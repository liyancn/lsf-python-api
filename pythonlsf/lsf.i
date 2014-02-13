/* 
* (C) Copyright IBM Corporation 2013
* 
* This library is free software; you can redistribute it and/or
* modify it under the terms of the Eclipse Public License.
* 
*/

/* File: lsf.i */
%module lsf
%include "cpointer.i"
%include "carrays.i"

FILE *fopen(char *filename, char *mode);
int fclose(FILE *f);

%{
#define SWIG_FILE_WITH_INIT
#include "lsf.h"
#include "lsbatch.h"
%}

%pointer_functions(int, intp)
%pointer_functions(float, floatp)

//  helper function for char **
%inline %{
PyObject * char_p_p_from_pylist(PyObject* list){
  PyObject * obj = 0;
  char ** ptr = 0;
  if (list == Py_None) {
    return NULL;
  } else if (PyList_Check(list)) {
    int size = PyList_Size(list);
    int i = 0;
    ptr = (char **) malloc((size+1)*sizeof(char *));
    for (i = 0; i < size; i++) {
      PyObject *o = PyList_GetItem(list,i);
      if (PyString_Check(o)){
        char* str = PyString_AsString(PyList_GetItem(list,i));
        char* newstr = malloc(strlen(str) + 1);
        strcpy(newstr, str);
        ptr[i] = newstr;
      }else {
        PyErr_SetString(PyExc_TypeError,"list must contain strings");
        int j = 0;
        for(j = 0; j < i-1; j++)
            free(ptr[j]);
        free(ptr);
        return NULL;
      }
      obj = SWIG_NewPointerObj(SWIG_as_voidptr(ptr), SWIGTYPE_p_p_char, 0);
    }
    return obj;
  } else {
    PyErr_SetString(PyExc_TypeError,"not a list");
    return obj;
  }
}
PyObject * char_p_p_to_pylist(PyObject* ptr, int size){
    void* cptr = 0;
    char** strptr = 0;
    int res = 0;
    PyObject * list = 0;
    int i = 0;
    res = SWIG_ConvertPtr(ptr, &cptr,SWIGTYPE_p_p_char, 0 |  0 );
    if (!SWIG_IsOK(res)) {
      PyErr_SetString(PyExc_TypeError,"not a SWIGTYPE_p_p_char");
      return NULL;
    }
    strptr = (char**)cptr;
    list = PyList_New(size);
    for (i = 0; i < size; i++) {
        PyList_SetItem(list,i,PyString_FromString(strptr[i]));
    }
    return list;
}
void char_p_p_free(PyObject* ptr, int size){
    void* cptr = 0;
    char** strptr = 0;
    int res = 0;
    int i = 0;
    res = SWIG_ConvertPtr(ptr, &cptr,SWIGTYPE_p_p_char, 0 |  0 );
    if (!SWIG_IsOK(res)) {
      PyErr_SetString(PyExc_TypeError,"not a SWIGTYPE_p_p_char"); 
      return ;
    }
    strptr = (char**)cptr;
    for (i = 0; i < size; i++) {
        free(strptr[i]);
    }
    free(strptr);
}
%}

%array_class(struct queueInfoEnt, queueInfoEntArray);
%array_class(struct hostInfoEnt, hostInfoEntArray);

%typemap(out) char ** {
  int len,i;
  len = 0;
  while ($1[len]) len++;
  $result = PyList_New(len);
  for (i = 0; i < len; i++) {
    PyList_SetItem($result,i,PyString_FromString($1[i]));
  }
}

// handle int arrays
%typemap(in) int [ANY] (int temp[$1_dim0]) {
  int i;
  for (i = 0; i < $1_dim0; i++) {
    PyObject *o = PySequence_GetItem($input,i);
      temp[i] = (int) PyInt_AsLong(o);
  }
  $1 = temp;
}

// See github issue 1
//%typemap(freearg) int [ANY] {
//  free((int *) $1);
//}

%typemap(out) int [ANY] {
  int i;
  $result = PyList_New($1_dim0);
  for (i = 0; i < $1_dim0; i++) {
    PyObject *o = PyLong_FromDouble((int) $1[i]);
    PyList_SetItem($result,i,o);
  }
}

// typemap for time_t
%typemap(in) time_t {
    $1 = (time_t) PyLong_AsLong($input);
}

%typemap(freearg) time_t {
    free((time_t *) $1);
}

%typemap(out) time_t {
    $result = PyLong_FromLong((long)$1);
}

/* 
 The following routines are not wrapped because SWIG has issues generating 
 proper code for them 
 */

// Following are ignored from lsf.h

%ignore getBEtime;
%ignore ls_gethostrespriority;
%ignore ls_loadoftype;
%ignore ls_lostconnection;
%ignore ls_nioclose;
%ignore ls_nioctl;
%ignore ls_niodump;
%ignore ls_nioinit;
%ignore ls_niokill;
%ignore ls_nionewtask;
%ignore ls_nioread;
%ignore ls_nioremovetask;
%ignore ls_nioselect;
%ignore ls_niosetdebug;
%ignore ls_niostatus;
%ignore ls_niotasks;
%ignore ls_niowrite;
%ignore ls_placeoftype;
%ignore ls_readrexlog;
%ignore ls_verrlog;
%ignore lsb_globalpolicy;
%ignore lsb_jobidindex2str;

// Following are ignored from lsbatch.h

%ignore lsb_readstatusline;

// Now include the rest...

%include "lsf.h"
%include "lsbatch.h"

%inline %{
PyObject * get_host_names() {
    struct hostInfo *hostinfo; 
    char   *resreq; 
    int    numhosts = 0; 
    int    options = 0; 
    
    resreq="";

    hostinfo = ls_gethostinfo(resreq, &numhosts, NULL, 0, options);      
    
    PyObject *result = PyList_New(numhosts);
    int i;
    for (i = 0; i < numhosts; i++) { 
        PyObject *o = PyString_FromString(hostinfo[i].hostName);
        PyList_SetItem(result,i,o);
    }
    
    return result;
}

PyObject * get_host_info() {
    struct hostInfo *hostinfo; 
    char   *resreq; 
    int    numhosts = 0; 
    int    options = 0; 
    
    resreq = "";

    hostinfo = ls_gethostinfo(resreq, &numhosts, NULL, 0, options);     
         
    PyObject *result = PyList_New(numhosts);
    int i;
    for (i = 0; i < numhosts; i++) {
        PyObject *o = SWIG_NewPointerObj(SWIG_as_voidptr(&hostinfo[i]), 
                                         SWIGTYPE_p_hostInfo, 0 |  0 );
        PyList_SetItem(result,i,o);
    }
    
    return result;
}    

PyObject * get_load_of_hosts() {
    struct hostLoad *hostload; 
    char   *resreq; 
    int    numhosts = 0; 
    int    options = 0; 
    
    resreq = "";

    hostload = ls_loadofhosts(resreq, &numhosts, 0, NULL, NULL, 0);
         
    PyObject *result = PyList_New(numhosts);
    int i;
    for (i = 0; i < numhosts; i++) {
        PyObject *o = SWIG_NewPointerObj(SWIG_as_voidptr(&hostload[i]),
                                         SWIGTYPE_p_hostLoad, 0 |  0 );
        PyList_SetItem(result,i,o);
    }
    
    return result;
}

PyObject * get_host_load(char *resreq, int index) {
    struct hostLoad *hosts; 

    int    numhosts = 0; 

    int    options = 0; 

    char   *fromhost = NULL; 

    hosts = ls_load(resreq, &numhosts, options, fromhost); 

    if (hosts == NULL || numhosts > 1) { 
        ls_perror("ls_load"); 
        exit(-1); 
    }

    PyObject *result = PyFloat_FromDouble(hosts[0].li[index]);
    return result;
}
%}
