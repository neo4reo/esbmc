#
# AX_CLANG([ACTION-IF-FOUND,[ACTION-IF-NOT-FOUND]])
#
# If both clang and clang++ are detected
# - Sets shell variable HAVE_CLANG='yes'
# - If ACTION-IF-FOUND is defined: Runs ACTION-IF-FOUND
# - If ACTION-IF-FOUND is undefined:
#   - Runs AC_SUBST for variables CLANG and CLANGXX, setting them to the
#     corresponding paths.
#
# If not both clang and clang++ are detected
# - Sets shell variable HAVE_CLANG='no'
# - Runs ACTION-IF-NOT-FOUND if defined
#

AC_DEFUN([AX_CLANG],
[
    AC_ARG_WITH([clang],
        AS_HELP_STRING([--with-clang=PATH],
            [Force given directory for clang. Note that this will override library path detection, so use this parameter only if default library detection fails and you know exactly where your clang libraries are located.]),
            [
                if test -d "$withval"
                then
                    ac_clang_path="$withval"
                    AC_PATH_PROGS([CLANG],[clang],[],[$ac_clang_path/bin])
                else
                    AC_MSG_ERROR(--with-clang expected directory name)
                fi
            ],
            dnl defaults to /usr/
            [
                ac_clang_path=$PATH
                AC_PATH_PROGS([CLANG],[clang],[],[$ac_clang_path])
            ]
    )

    if test "x$CLANG" = "x"; then
        ifelse([$3], , :, [$3])
    fi

    dnl check clang version
    AC_MSG_CHECKING(if clang >= $1)

    clangversion=0
    _version=$1
    clangversion=`$CLANG --version 2>/dev/null`
    if test "x$?" = "x0"; then
        clangversion=`echo "$clangversion" | tr '\n' ' ' | sed 's/^[[^0-9]]*\([[0-9]][[0-9.]]*[[0-9]]\).*$/\1/g'`
        clangversion=`echo "$clangversion" | sed 's/\([[0-9]]*\.[[0-9]]*\)\.[[0-9]]*/\1/g'`
        V_CHECK=`expr $clangversion \>= $_version`
        if test "$V_CHECK" != "1" ; then
            AC_MSG_WARN([Failure: ESBMC requires clang >= $1 but only found clang $clangversion.])
            ax_clang_ok='no'
        else
            ax_clang_ok='yes'
        fi
    else
        ax_clang_ok='no'
    fi

    if test "x$ax_clang_ok" = "xyes"; then
        AC_MSG_RESULT(yes ($clangversion))
    else
        AC_MSG_RESULT(no)
        ifelse([$3], , :, [$3])
    fi

    dnl Now search for the libraries
    AC_MSG_CHECKING(clang lib directory)
    succeeded=no

    dnl On 64-bit systems check for system libraries in both lib64 and lib.
    dnl The former is specified by FHS, but e.g. Debian does not adhere to
    dnl this (as it rises problems for generic multi-arch support).
    dnl The last entry in the list is chosen by default when no libraries
    dnl are found, e.g. when only header-only libraries are installed!
    libsubdirs="lib"
    ax_arch=`uname -m`
    case $ax_arch in
      x86_64)
        libsubdirs="lib64 libx32 lib lib64"
        ;;
      ppc64|s390x|sparc64|aarch64|ppc64le)
        libsubdirs="lib64 lib lib64 ppc64le"
        ;;
    esac

    dnl allow for real multi-arch paths e.g. /usr/lib/x86_64-linux-gnu. Give
    dnl them priority over the other paths since, if libs are found there, they
    dnl are almost assuredly the ones desired.
    AC_REQUIRE([AC_CANONICAL_HOST])
    libsubdirs="lib/${host_cpu}-${host_os} $libsubdirs"

    case ${host_cpu} in
      i?86)
        libsubdirs="lib/i386-${host_os} $libsubdirs"
        ;;
    esac

    lib_ext="dylib"
    if test `uname` != "Darwin" ; then
        lib_ext="so"
    fi

    dnl Check the system location for clang libraries
    clang_includes_path=$ac_clang_path/include/clang
    for libsubdir in $libsubdirs ; do
        if ls "$ac_clang_path/$libsubdir/libclang"* >/dev/null 2>&1 ; then break; fi
    done

    for i in `ls -d $ac_clang_path/$libsubdir/libclang.$lib_ext.* 2>/dev/null`; do
        _version_tmp=`echo $i | sed "s#$ac_clang_path/$libsubdir/##" | sed "s/libclang.$lib_ext.//"`
        V_CHECK=`expr $_version_tmp \> $_version`
        if test "$V_CHECK" != "1" ; then
                continue
        fi

        succeeded=yes
        clang_libs_path=$ac_clang_path/$libsubdir
        break;
    done

    if test "$succeeded" != "yes" ; then
        AC_MSG_RESULT(no)
        ifelse([$3], , :, [$3])
    else
        AC_MSG_RESULT($clang_libs_path)
    fi

    dnl Look for clang libs
    clanglibs="Tooling Frontend Parse Sema Edit Analysis AST Lex Basic Driver Serialization"
    for lib in $clanglibs ; do
        AC_MSG_CHECKING(if we can find libclang$lib.$lib_ext)
        if ls "$clang_libs_path/libclang$lib"* >/dev/null 2>&1 ; then
            clang_LIBS="$clang_LIBS -lclang$lib"
            AC_MSG_RESULT(yes)
        else
            AC_MSG_NOTICE([Can't find libclang$lib])
            ifelse([$3], , :, [$3])
        fi
    done

    dnl Search if clang was shipped with a symbolic link call libgomp.so
    dnl We actually link with libgomp.so and this link breaks the old frontend
    AC_MSG_CHECKING(if $clang_libs_path/libgomp.so is present)
    if ls -L "$clang_libs_path/libgomp.so" >/dev/null 2>&1 ; then
        AC_MSG_ERROR([Found libgomp.so on $clang_libs_path. ESBMC is linked against the GNU libgomp and the one shipped with clang is known to cause issues on our tool. Please, remove it before continuing.])
    fi
    AC_MSG_RESULT(no)

    clang_CPPFLAGS="-I$clang_includes_path"
    clang_LDFLAGS="-L$clang_libs_path"

    CPPFLAGS_SAVED="$CPPFLAGS"
    CPPFLAGS="$CPPFLAGS $clang_CPPFLAGS"
    export CPPFLAGS

    LDFLAGS_SAVED="$LDFLAGS"
    LDFLAGS="$LDFLAGS $clang_LDFLAGS"
    export LDFLAGS

    LIBS_SAVED="$LIBS"
    LIBS="$LIBS $clang_LIBS"
    export LIBS

    if test "$succeeded" != "yes" ; then
        CPPFLAGS="$CPPFLAGS_SAVED"
        LDFLAGS="$LDFLAGS_SAVED"
        LIBS="$LIBS_SAVED"

        dnl execute ACTION-IF-NOT-FOUND (if present):
        ifelse([$3], , :, [$3])
    else
        AC_SUBST(clang_CPPFLAGS)
        AC_SUBST(clang_LDFLAGS)
        AC_SUBST(clang_LIBS)
        AC_DEFINE(HAVE_clang,,[define if the clang library is available])
        dnl execute ACTION-IF-FOUND (if present):
        ifelse([$2], , :, [$2])
    fi
])
