/*******************************************************************\

Module: Container for C-Strings

Author: Daniel Kroening, kroening@kroening.com

\*******************************************************************/

#ifndef DSTRING_H
#define DSTRING_H

#include <iostream>
#include <util/string_container.h>

class dstring
{
public:
  // this is safe for static objects
  inline dstring():no(0)
  {
  }

  // this one is not safe for static objects
  inline dstring(const char *s):no(string_container[s])
  {
  }

  // this one is not safe for static objects
  inline dstring(const std::string &s):no(string_container[s])
  {
  }

  // access
  
  inline bool empty() const
  {
    return no==0; // string 0 is exactly the empty string
  }
  
  inline char operator[](unsigned i) const
  {
    return as_string()[i];
  }
  
  // warning! the address returned is not stable
  inline const char *c_str() const
  {
    return as_string().c_str();
  }
  
  inline size_t size() const
  {
    return as_string().size();
  }

  // ordering -- not the same as lexicographical ordering

  inline bool operator< (const dstring &b) const { return no<b.no; }

  // comparison with same type

  inline bool operator==(const dstring &b) const
  { return no==b.no; } // really fast equality testing

  inline bool operator!=(const dstring &b) const
  { return no!=b.no; } // really fast equality testing

  // comparison with other types

  bool operator==(const char *b) const { return as_string()==b; }
  bool operator!=(const char *b) const { return as_string()!=b; }

  bool operator==(const std::string &b) const { return as_string()==b; }
  bool operator!=(const std::string &b) const { return as_string()!=b; }
  bool operator< (const std::string &b) const { return as_string()< b; }
  bool operator> (const std::string &b) const { return as_string()> b; }
  bool operator<=(const std::string &b) const { return as_string()<=b; }
  bool operator>=(const std::string &b) const { return as_string()>=b; }
  
  int compare(const dstring &b) const
  {
    if(no==b.no) return 0; // equal
    return as_string().compare(b.as_string());
  }
  
  inline friend bool ordering(const dstring &a, const dstring &b)
  {
    return a.no<b.no;
  }

  // warning! the reference returned is not stable
  inline const std::string &as_string() const
  { return string_container.get_string(no); }
   
  // modifying
  
  inline void clear()
  { no=0; }
   
  inline void swap(dstring &b)
  { unsigned t=no; no=b.no; b.no=t; }

  inline dstring &operator=(const dstring &b) = default;
  
  inline friend std::ostream &operator<<(std::ostream &out, const dstring &a)
  {
    return out << a.as_string();
  }
  
  inline friend size_t hash_string(const dstring &s)
  {
    return s.hash();
  }

  inline size_t hash() const
  {
    return no;
  }
  
  inline unsigned get_no() const
  {
    return no;
  }
  
protected:
  unsigned no;
};

struct dstring_hash hash_map_hasher_superclass(dstring)
{
public:
  size_t operator()(const dstring &s) const { return s.hash(); }
  bool operator()(const dstring &s1, const dstring &s2) const {
	return s1.hash() < s2.hash();
  }
};

size_t hash_string(const dstring &s);

std::ostream &operator << (std::ostream &out, const dstring &a);

#endif
