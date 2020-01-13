
typedef long unsigned int size_t;
extern void *memcpy (void *__restrict __dest, const void *__restrict __src,
       size_t __n) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern void *memmove (void *__dest, const void *__src, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern void *memccpy (void *__restrict __dest, const void *__restrict __src,
        int __c, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern void *memset (void *__s, int __c, size_t __n) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern int memcmp (const void *__s1, const void *__s2, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern void *memchr (const void *__s, int __c, size_t __n)
      __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1)));
extern char *strcpy (char *__restrict __dest, const char *__restrict __src)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *strncpy (char *__restrict __dest,
        const char *__restrict __src, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *strcat (char *__restrict __dest, const char *__restrict __src)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *strncat (char *__restrict __dest, const char *__restrict __src,
        size_t __n) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int strcmp (const char *__s1, const char *__s2)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern int strncmp (const char *__s1, const char *__s2, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern int strcoll (const char *__s1, const char *__s2)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern size_t strxfrm (char *__restrict __dest,
         const char *__restrict __src, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2)));
struct __locale_struct
{
  struct __locale_data *__locales[13];
  const unsigned short int *__ctype_b;
  const int *__ctype_tolower;
  const int *__ctype_toupper;
  const char *__names[13];
};
typedef struct __locale_struct *__locale_t;
typedef __locale_t locale_t;
extern int strcoll_l (const char *__s1, const char *__s2, locale_t __l)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2, 3)));
extern size_t strxfrm_l (char *__dest, const char *__src, size_t __n,
    locale_t __l) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2, 4)));
extern char *strdup (const char *__s)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__malloc__)) __attribute__ ((__nonnull__ (1)));
extern char *strndup (const char *__string, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__malloc__)) __attribute__ ((__nonnull__ (1)));
extern char *strchr (const char *__s, int __c)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1)));
extern char *strrchr (const char *__s, int __c)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1)));
extern size_t strcspn (const char *__s, const char *__reject)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern size_t strspn (const char *__s, const char *__accept)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *strpbrk (const char *__s, const char *__accept)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *strstr (const char *__haystack, const char *__needle)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *strtok (char *__restrict __s, const char *__restrict __delim)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2)));
extern char *__strtok_r (char *__restrict __s,
    const char *__restrict __delim,
    char **__restrict __save_ptr)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2, 3)));
extern char *strtok_r (char *__restrict __s, const char *__restrict __delim,
         char **__restrict __save_ptr)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2, 3)));
extern size_t strlen (const char *__s)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1)));
extern size_t strnlen (const char *__string, size_t __maxlen)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1)));
extern char *strerror (int __errnum) __attribute__ ((__nothrow__ , __leaf__));
extern int strerror_r (int __errnum, char *__buf, size_t __buflen) __asm__ ("" "__xpg_strerror_r") __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2)));
extern char *strerror_l (int __errnum, locale_t __l) __attribute__ ((__nothrow__ , __leaf__));

extern int bcmp (const void *__s1, const void *__s2, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern void bcopy (const void *__src, void *__dest, size_t __n)
  __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern void bzero (void *__s, size_t __n) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern char *index (const char *__s, int __c)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1)));
extern char *rindex (const char *__s, int __c)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1)));
extern int ffs (int __i) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__));
extern int strcasecmp (const char *__s1, const char *__s2)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern int strncasecmp (const char *__s1, const char *__s2, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2)));
extern int strcasecmp_l (const char *__s1, const char *__s2, locale_t __loc)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2, 3)));
extern int strncasecmp_l (const char *__s1, const char *__s2,
     size_t __n, locale_t __loc)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1, 2, 4)));

extern void explicit_bzero (void *__s, size_t __n) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern char *strsep (char **__restrict __stringp,
       const char *__restrict __delim)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *strsignal (int __sig) __attribute__ ((__nothrow__ , __leaf__));
extern char *__stpcpy (char *__restrict __dest, const char *__restrict __src)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *stpcpy (char *__restrict __dest, const char *__restrict __src)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *__stpncpy (char *__restrict __dest,
   const char *__restrict __src, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *stpncpy (char *__restrict __dest,
        const char *__restrict __src, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));


typedef unsigned char __u_char;
typedef unsigned short int __u_short;
typedef unsigned int __u_int;
typedef unsigned long int __u_long;
typedef signed char __int8_t;
typedef unsigned char __uint8_t;
typedef signed short int __int16_t;
typedef unsigned short int __uint16_t;
typedef signed int __int32_t;
typedef unsigned int __uint32_t;
typedef signed long int __int64_t;
typedef unsigned long int __uint64_t;
typedef long int __quad_t;
typedef unsigned long int __u_quad_t;
typedef long int __intmax_t;
typedef unsigned long int __uintmax_t;
typedef unsigned long int __dev_t;
typedef unsigned int __uid_t;
typedef unsigned int __gid_t;
typedef unsigned long int __ino_t;
typedef unsigned long int __ino64_t;
typedef unsigned int __mode_t;
typedef unsigned long int __nlink_t;
typedef long int __off_t;
typedef long int __off64_t;
typedef int __pid_t;
typedef struct { int __val[2]; } __fsid_t;
typedef long int __clock_t;
typedef unsigned long int __rlim_t;
typedef unsigned long int __rlim64_t;
typedef unsigned int __id_t;
typedef long int __time_t;
typedef unsigned int __useconds_t;
typedef long int __suseconds_t;
typedef int __daddr_t;
typedef int __key_t;
typedef int __clockid_t;
typedef void * __timer_t;
typedef long int __blksize_t;
typedef long int __blkcnt_t;
typedef long int __blkcnt64_t;
typedef unsigned long int __fsblkcnt_t;
typedef unsigned long int __fsblkcnt64_t;
typedef unsigned long int __fsfilcnt_t;
typedef unsigned long int __fsfilcnt64_t;
typedef long int __fsword_t;
typedef long int __ssize_t;
typedef long int __syscall_slong_t;
typedef unsigned long int __syscall_ulong_t;
typedef __off64_t __loff_t;
typedef __quad_t *__qaddr_t;
typedef char *__caddr_t;
typedef long int __intptr_t;
typedef unsigned int __socklen_t;
typedef int __sig_atomic_t;
struct _IO_FILE;
typedef struct _IO_FILE __FILE;
struct _IO_FILE;
typedef struct _IO_FILE FILE;
typedef struct
{
  int __count;
  union
  {
    unsigned int __wch;
    char __wchb[4];
  } __value;
} __mbstate_t;
typedef struct
{
  __off_t __pos;
  __mbstate_t __state;
} _G_fpos_t;
typedef struct
{
  __off64_t __pos;
  __mbstate_t __state;
} _G_fpos64_t;
typedef __builtin_va_list __gnuc_va_list;
struct _IO_jump_t; struct _IO_FILE;
typedef void _IO_lock_t;
struct _IO_marker {
  struct _IO_marker *_next;
  struct _IO_FILE *_sbuf;
  int _pos;
};
enum __codecvt_result
{
  __codecvt_ok,
  __codecvt_partial,
  __codecvt_error,
  __codecvt_noconv
};
struct _IO_FILE {
  int _flags;
  char* _IO_read_ptr;
  char* _IO_read_end;
  char* _IO_read_base;
  char* _IO_write_base;
  char* _IO_write_ptr;
  char* _IO_write_end;
  char* _IO_buf_base;
  char* _IO_buf_end;
  char *_IO_save_base;
  char *_IO_backup_base;
  char *_IO_save_end;
  struct _IO_marker *_markers;
  struct _IO_FILE *_chain;
  int _fileno;
  int _flags2;
  __off_t _old_offset;
  unsigned short _cur_column;
  signed char _vtable_offset;
  char _shortbuf[1];
  _IO_lock_t *_lock;
  __off64_t _offset;
  void *__pad1;
  void *__pad2;
  void *__pad3;
  void *__pad4;
  size_t __pad5;
  int _mode;
  char _unused2[15 * sizeof (int) - 4 * sizeof (void *) - sizeof (size_t)];
};
typedef struct _IO_FILE _IO_FILE;
struct _IO_FILE_plus;
extern struct _IO_FILE_plus _IO_2_1_stdin_;
extern struct _IO_FILE_plus _IO_2_1_stdout_;
extern struct _IO_FILE_plus _IO_2_1_stderr_;
typedef __ssize_t __io_read_fn (void *__cookie, char *__buf, size_t __nbytes);
typedef __ssize_t __io_write_fn (void *__cookie, const char *__buf,
     size_t __n);
typedef int __io_seek_fn (void *__cookie, __off64_t *__pos, int __w);
typedef int __io_close_fn (void *__cookie);
extern int __underflow (_IO_FILE *);
extern int __uflow (_IO_FILE *);
extern int __overflow (_IO_FILE *, int);
extern int _IO_getc (_IO_FILE *__fp);
extern int _IO_putc (int __c, _IO_FILE *__fp);
extern int _IO_feof (_IO_FILE *__fp) __attribute__ ((__nothrow__ , __leaf__));
extern int _IO_ferror (_IO_FILE *__fp) __attribute__ ((__nothrow__ , __leaf__));
extern int _IO_peekc_locked (_IO_FILE *__fp);
extern void _IO_flockfile (_IO_FILE *) __attribute__ ((__nothrow__ , __leaf__));
extern void _IO_funlockfile (_IO_FILE *) __attribute__ ((__nothrow__ , __leaf__));
extern int _IO_ftrylockfile (_IO_FILE *) __attribute__ ((__nothrow__ , __leaf__));
extern int _IO_vfscanf (_IO_FILE * __restrict, const char * __restrict,
   __gnuc_va_list, int *__restrict);
extern int _IO_vfprintf (_IO_FILE *__restrict, const char *__restrict,
    __gnuc_va_list);
extern __ssize_t _IO_padn (_IO_FILE *, int, __ssize_t);
extern size_t _IO_sgetn (_IO_FILE *, void *, size_t);
extern __off64_t _IO_seekoff (_IO_FILE *, __off64_t, int, int);
extern __off64_t _IO_seekpos (_IO_FILE *, __off64_t, int);
extern void _IO_free_backup_area (_IO_FILE *) __attribute__ ((__nothrow__ , __leaf__));
typedef __gnuc_va_list va_list;
typedef __off64_t off_t;
typedef __ssize_t ssize_t;
typedef _G_fpos64_t fpos_t;
extern struct _IO_FILE *stdin;
extern struct _IO_FILE *stdout;
extern struct _IO_FILE *stderr;
extern int remove (const char *__filename) __attribute__ ((__nothrow__ , __leaf__));
extern int rename (const char *__old, const char *__new) __attribute__ ((__nothrow__ , __leaf__));
extern int renameat (int __oldfd, const char *__old, int __newfd,
       const char *__new) __attribute__ ((__nothrow__ , __leaf__));
extern FILE *tmpfile (void) __asm__ ("" "tmpfile64") ;
extern char *tmpnam (char *__s) __attribute__ ((__nothrow__ , __leaf__)) ;
extern char *tmpnam_r (char *__s) __attribute__ ((__nothrow__ , __leaf__)) ;
extern char *tempnam (const char *__dir, const char *__pfx)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__malloc__)) ;
extern int fclose (FILE *__stream);
extern int fflush (FILE *__stream);
extern int fflush_unlocked (FILE *__stream);
extern FILE *fopen (const char *__restrict __filename, const char *__restrict __modes) __asm__ ("" "fopen64")
  ;
extern FILE *freopen (const char *__restrict __filename, const char *__restrict __modes, FILE *__restrict __stream) __asm__ ("" "freopen64")
  ;
extern FILE *fdopen (int __fd, const char *__modes) __attribute__ ((__nothrow__ , __leaf__)) ;
extern FILE *fmemopen (void *__s, size_t __len, const char *__modes)
  __attribute__ ((__nothrow__ , __leaf__)) ;
extern FILE *open_memstream (char **__bufloc, size_t *__sizeloc) __attribute__ ((__nothrow__ , __leaf__)) ;
extern void setbuf (FILE *__restrict __stream, char *__restrict __buf) __attribute__ ((__nothrow__ , __leaf__));
extern int setvbuf (FILE *__restrict __stream, char *__restrict __buf,
      int __modes, size_t __n) __attribute__ ((__nothrow__ , __leaf__));
extern void setbuffer (FILE *__restrict __stream, char *__restrict __buf,
         size_t __size) __attribute__ ((__nothrow__ , __leaf__));
extern void setlinebuf (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));
extern int fprintf (FILE *__restrict __stream,
      const char *__restrict __format, ...);
extern int printf (const char *__restrict __format, ...);
extern int sprintf (char *__restrict __s,
      const char *__restrict __format, ...) __attribute__ ((__nothrow__));
extern int vfprintf (FILE *__restrict __s, const char *__restrict __format,
       __gnuc_va_list __arg);
extern int vprintf (const char *__restrict __format, __gnuc_va_list __arg);
extern int vsprintf (char *__restrict __s, const char *__restrict __format,
       __gnuc_va_list __arg) __attribute__ ((__nothrow__));
extern int snprintf (char *__restrict __s, size_t __maxlen,
       const char *__restrict __format, ...)
     __attribute__ ((__nothrow__)) __attribute__ ((__format__ (__printf__, 3, 4)));
extern int vsnprintf (char *__restrict __s, size_t __maxlen,
        const char *__restrict __format, __gnuc_va_list __arg)
     __attribute__ ((__nothrow__)) __attribute__ ((__format__ (__printf__, 3, 0)));
extern int vdprintf (int __fd, const char *__restrict __fmt,
       __gnuc_va_list __arg)
     __attribute__ ((__format__ (__printf__, 2, 0)));
extern int dprintf (int __fd, const char *__restrict __fmt, ...)
     __attribute__ ((__format__ (__printf__, 2, 3)));
extern int fscanf (FILE *__restrict __stream,
     const char *__restrict __format, ...) ;
extern int scanf (const char *__restrict __format, ...) ;
extern int sscanf (const char *__restrict __s,
     const char *__restrict __format, ...) __attribute__ ((__nothrow__ , __leaf__));
extern int fscanf (FILE *__restrict __stream, const char *__restrict __format, ...) __asm__ ("" "__isoc99_fscanf") ;
extern int scanf (const char *__restrict __format, ...) __asm__ ("" "__isoc99_scanf") ;
extern int sscanf (const char *__restrict __s, const char *__restrict __format, ...) __asm__ ("" "__isoc99_sscanf") __attribute__ ((__nothrow__ , __leaf__));
extern int vfscanf (FILE *__restrict __s, const char *__restrict __format,
      __gnuc_va_list __arg)
     __attribute__ ((__format__ (__scanf__, 2, 0))) ;
extern int vscanf (const char *__restrict __format, __gnuc_va_list __arg)
     __attribute__ ((__format__ (__scanf__, 1, 0))) ;
extern int vsscanf (const char *__restrict __s,
      const char *__restrict __format, __gnuc_va_list __arg)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__format__ (__scanf__, 2, 0)));
extern int vfscanf (FILE *__restrict __s, const char *__restrict __format, __gnuc_va_list __arg) __asm__ ("" "__isoc99_vfscanf")
     __attribute__ ((__format__ (__scanf__, 2, 0))) ;
extern int vscanf (const char *__restrict __format, __gnuc_va_list __arg) __asm__ ("" "__isoc99_vscanf")
     __attribute__ ((__format__ (__scanf__, 1, 0))) ;
extern int vsscanf (const char *__restrict __s, const char *__restrict __format, __gnuc_va_list __arg) __asm__ ("" "__isoc99_vsscanf") __attribute__ ((__nothrow__ , __leaf__))
     __attribute__ ((__format__ (__scanf__, 2, 0)));
extern int fgetc (FILE *__stream);
extern int getc (FILE *__stream);
extern int getchar (void);
extern int getc_unlocked (FILE *__stream);
extern int getchar_unlocked (void);
extern int fgetc_unlocked (FILE *__stream);
extern int fputc (int __c, FILE *__stream);
extern int putc (int __c, FILE *__stream);
extern int putchar (int __c);
extern int fputc_unlocked (int __c, FILE *__stream);
extern int putc_unlocked (int __c, FILE *__stream);
extern int putchar_unlocked (int __c);
extern int getw (FILE *__stream);
extern int putw (int __w, FILE *__stream);
extern char *fgets (char *__restrict __s, int __n, FILE *__restrict __stream)
     ;
extern __ssize_t __getdelim (char **__restrict __lineptr,
          size_t *__restrict __n, int __delimiter,
          FILE *__restrict __stream) ;
extern __ssize_t getdelim (char **__restrict __lineptr,
        size_t *__restrict __n, int __delimiter,
        FILE *__restrict __stream) ;
extern __ssize_t getline (char **__restrict __lineptr,
       size_t *__restrict __n,
       FILE *__restrict __stream) ;
extern int fputs (const char *__restrict __s, FILE *__restrict __stream);
extern int puts (const char *__s);
extern int ungetc (int __c, FILE *__stream);
extern size_t fread (void *__restrict __ptr, size_t __size,
       size_t __n, FILE *__restrict __stream) ;
extern size_t fwrite (const void *__restrict __ptr, size_t __size,
        size_t __n, FILE *__restrict __s);
extern size_t fread_unlocked (void *__restrict __ptr, size_t __size,
         size_t __n, FILE *__restrict __stream) ;
extern size_t fwrite_unlocked (const void *__restrict __ptr, size_t __size,
          size_t __n, FILE *__restrict __stream);
extern int fseek (FILE *__stream, long int __off, int __whence);
extern long int ftell (FILE *__stream) ;
extern void rewind (FILE *__stream);
extern int fseeko (FILE *__stream, __off64_t __off, int __whence) __asm__ ("" "fseeko64");
extern __off64_t ftello (FILE *__stream) __asm__ ("" "ftello64");
extern int fgetpos (FILE *__restrict __stream, fpos_t *__restrict __pos) __asm__ ("" "fgetpos64");
extern int fsetpos (FILE *__stream, const fpos_t *__pos) __asm__ ("" "fsetpos64");
extern void clearerr (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));
extern int feof (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;
extern int ferror (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;
extern void clearerr_unlocked (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));
extern int feof_unlocked (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;
extern int ferror_unlocked (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;
extern void perror (const char *__s);
extern int sys_nerr;
extern const char *const sys_errlist[];
extern int fileno (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;
extern int fileno_unlocked (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;
extern FILE *popen (const char *__command, const char *__modes) ;
extern int pclose (FILE *__stream);
extern char *ctermid (char *__s) __attribute__ ((__nothrow__ , __leaf__));
extern void flockfile (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));
extern int ftrylockfile (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;
extern void funlockfile (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));

typedef int wchar_t;

typedef struct
  {
    int quot;
    int rem;
  } div_t;
typedef struct
  {
    long int quot;
    long int rem;
  } ldiv_t;
__extension__ typedef struct
  {
    long long int quot;
    long long int rem;
  } lldiv_t;
extern size_t __ctype_get_mb_cur_max (void) __attribute__ ((__nothrow__ , __leaf__)) ;
extern double atof (const char *__nptr)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1))) ;
extern int atoi (const char *__nptr)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1))) ;
extern long int atol (const char *__nptr)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1))) ;
__extension__ extern long long int atoll (const char *__nptr)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1))) ;
extern double strtod (const char *__restrict __nptr,
        char **__restrict __endptr)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern float strtof (const char *__restrict __nptr,
       char **__restrict __endptr) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern long double strtold (const char *__restrict __nptr,
       char **__restrict __endptr)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern long int strtol (const char *__restrict __nptr,
   char **__restrict __endptr, int __base)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern unsigned long int strtoul (const char *__restrict __nptr,
      char **__restrict __endptr, int __base)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
__extension__
extern long long int strtoq (const char *__restrict __nptr,
        char **__restrict __endptr, int __base)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
__extension__
extern unsigned long long int strtouq (const char *__restrict __nptr,
           char **__restrict __endptr, int __base)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
__extension__
extern long long int strtoll (const char *__restrict __nptr,
         char **__restrict __endptr, int __base)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
__extension__
extern unsigned long long int strtoull (const char *__restrict __nptr,
     char **__restrict __endptr, int __base)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern char *l64a (long int __n) __attribute__ ((__nothrow__ , __leaf__)) ;
extern long int a64l (const char *__s)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__pure__)) __attribute__ ((__nonnull__ (1))) ;

typedef __u_char u_char;
typedef __u_short u_short;
typedef __u_int u_int;
typedef __u_long u_long;
typedef __quad_t quad_t;
typedef __u_quad_t u_quad_t;
typedef __fsid_t fsid_t;
typedef __loff_t loff_t;
typedef __ino64_t ino_t;
typedef __dev_t dev_t;
typedef __gid_t gid_t;
typedef __mode_t mode_t;
typedef __nlink_t nlink_t;
typedef __uid_t uid_t;
typedef __pid_t pid_t;
typedef __id_t id_t;
typedef __daddr_t daddr_t;
typedef __caddr_t caddr_t;
typedef __key_t key_t;
typedef __clock_t clock_t;
typedef __clockid_t clockid_t;
typedef __time_t time_t;
typedef __timer_t timer_t;
typedef unsigned long int ulong;
typedef unsigned short int ushort;
typedef unsigned int uint;
typedef __int8_t int8_t;
typedef __int16_t int16_t;
typedef __int32_t int32_t;
typedef __int64_t int64_t;
typedef unsigned int u_int8_t __attribute__ ((__mode__ (__QI__)));
typedef unsigned int u_int16_t __attribute__ ((__mode__ (__HI__)));
typedef unsigned int u_int32_t __attribute__ ((__mode__ (__SI__)));
typedef unsigned int u_int64_t __attribute__ ((__mode__ (__DI__)));
typedef int register_t __attribute__ ((__mode__ (__word__)));
static __inline unsigned int
__bswap_32 (unsigned int __bsx)
{
  return __builtin_bswap32 (__bsx);
}
static __inline __uint64_t
__bswap_64 (__uint64_t __bsx)
{
  return __builtin_bswap64 (__bsx);
}
static __inline __uint16_t
__uint16_identity (__uint16_t __x)
{
  return __x;
}
static __inline __uint32_t
__uint32_identity (__uint32_t __x)
{
  return __x;
}
static __inline __uint64_t
__uint64_identity (__uint64_t __x)
{
  return __x;
}
typedef struct
{
  unsigned long int __val[(1024 / (8 * sizeof (unsigned long int)))];
} __sigset_t;
typedef __sigset_t sigset_t;
struct timeval
{
  __time_t tv_sec;
  __suseconds_t tv_usec;
};
//struct timespec
//{
//  __time_t tv_sec;
//  __syscall_slong_t tv_nsec;
//};
typedef __suseconds_t suseconds_t;
typedef long int __fd_mask;
typedef struct
  {
    __fd_mask __fds_bits[1024 / (8 * (int) sizeof (__fd_mask))];
  } fd_set;
typedef __fd_mask fd_mask;

extern int select (int __nfds, fd_set *__restrict __readfds,
     fd_set *__restrict __writefds,
     fd_set *__restrict __exceptfds,
     struct timeval *__restrict __timeout);
extern int pselect (int __nfds, fd_set *__restrict __readfds,
      fd_set *__restrict __writefds,
      fd_set *__restrict __exceptfds,
      const struct timespec *__restrict __timeout,
      const __sigset_t *__restrict __sigmask);


extern unsigned int gnu_dev_major (__dev_t __dev) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__));
extern unsigned int gnu_dev_minor (__dev_t __dev) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__));
extern __dev_t gnu_dev_makedev (unsigned int __major, unsigned int __minor) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__));

typedef __blksize_t blksize_t;
typedef __blkcnt64_t blkcnt_t;
typedef __fsblkcnt64_t fsblkcnt_t;
typedef __fsfilcnt64_t fsfilcnt_t;
struct __pthread_rwlock_arch_t
{
  unsigned int __readers;
  unsigned int __writers;
  unsigned int __wrphase_futex;
  unsigned int __writers_futex;
  unsigned int __pad3;
  unsigned int __pad4;
  int __cur_writer;
  int __shared;
  signed char __rwelision;
  unsigned char __pad1[7];
  unsigned long int __pad2;
  unsigned int __flags;
};
typedef struct __pthread_internal_list
{
  struct __pthread_internal_list *__prev;
  struct __pthread_internal_list *__next;
} __pthread_list_t;
struct __pthread_mutex_s
{
  int __lock ;
  unsigned int __count;
  int __owner;
  unsigned int __nusers;
  int __kind;

  short __spins; short __elision;
  __pthread_list_t __list;

};
struct __pthread_cond_s
{
  __extension__ union
  {
    __extension__ unsigned long long int __wseq;
    struct
    {
      unsigned int __low;
      unsigned int __high;
    } __wseq32;
  };
  __extension__ union
  {
    __extension__ unsigned long long int __g1_start;
    struct
    {
      unsigned int __low;
      unsigned int __high;
    } __g1_start32;
  };
  unsigned int __g_refs[2] ;
  unsigned int __g_size[2];
  unsigned int __g1_orig_size;
  unsigned int __wrefs;
  unsigned int __g_signals[2];
};
typedef unsigned long int pthread_t;
typedef union
{
  char __size[4];
  int __align;
} pthread_mutexattr_t;
typedef union
{
  char __size[4];
  int __align;
} pthread_condattr_t;
typedef unsigned int pthread_key_t;
typedef int pthread_once_t;
union pthread_attr_t
{
  char __size[56];
  long int __align;
};
typedef union pthread_attr_t pthread_attr_t;
typedef union
{
  struct __pthread_mutex_s __data;
  char __size[40];
  long int __align;
} pthread_mutex_t;
typedef union
{
  struct __pthread_cond_s __data;
  char __size[48];
  __extension__ long long int __align;
} pthread_cond_t;
typedef union
{
  struct __pthread_rwlock_arch_t __data;
  char __size[56];
  long int __align;
} pthread_rwlock_t;
typedef union
{
  char __size[8];
  long int __align;
} pthread_rwlockattr_t;
typedef volatile int pthread_spinlock_t;
typedef union
{
  char __size[32];
  long int __align;
} pthread_barrier_t;
typedef union
{
  char __size[4];
  int __align;
} pthread_barrierattr_t;

extern long int random (void) __attribute__ ((__nothrow__ , __leaf__));
extern void srandom (unsigned int __seed) __attribute__ ((__nothrow__ , __leaf__));
extern char *initstate (unsigned int __seed, char *__statebuf,
   size_t __statelen) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2)));
extern char *setstate (char *__statebuf) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
struct random_data
  {
    int32_t *fptr;
    int32_t *rptr;
    int32_t *state;
    int rand_type;
    int rand_deg;
    int rand_sep;
    int32_t *end_ptr;
  };
extern int random_r (struct random_data *__restrict __buf,
       int32_t *__restrict __result) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int srandom_r (unsigned int __seed, struct random_data *__buf)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2)));
extern int initstate_r (unsigned int __seed, char *__restrict __statebuf,
   size_t __statelen,
   struct random_data *__restrict __buf)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2, 4)));
extern int setstate_r (char *__restrict __statebuf,
         struct random_data *__restrict __buf)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int rand (void) __attribute__ ((__nothrow__ , __leaf__));
extern void srand (unsigned int __seed) __attribute__ ((__nothrow__ , __leaf__));
extern int rand_r (unsigned int *__seed) __attribute__ ((__nothrow__ , __leaf__));
extern double drand48 (void) __attribute__ ((__nothrow__ , __leaf__));
extern double erand48 (unsigned short int __xsubi[3]) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern long int lrand48 (void) __attribute__ ((__nothrow__ , __leaf__));
extern long int nrand48 (unsigned short int __xsubi[3])
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern long int mrand48 (void) __attribute__ ((__nothrow__ , __leaf__));
extern long int jrand48 (unsigned short int __xsubi[3])
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern void srand48 (long int __seedval) __attribute__ ((__nothrow__ , __leaf__));
extern unsigned short int *seed48 (unsigned short int __seed16v[3])
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern void lcong48 (unsigned short int __param[7]) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
struct drand48_data
  {
    unsigned short int __x[3];
    unsigned short int __old_x[3];
    unsigned short int __c;
    unsigned short int __init;
    __extension__ unsigned long long int __a;
  };
extern int drand48_r (struct drand48_data *__restrict __buffer,
        double *__restrict __result) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int erand48_r (unsigned short int __xsubi[3],
        struct drand48_data *__restrict __buffer,
        double *__restrict __result) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int lrand48_r (struct drand48_data *__restrict __buffer,
        long int *__restrict __result)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int nrand48_r (unsigned short int __xsubi[3],
        struct drand48_data *__restrict __buffer,
        long int *__restrict __result)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int mrand48_r (struct drand48_data *__restrict __buffer,
        long int *__restrict __result)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int jrand48_r (unsigned short int __xsubi[3],
        struct drand48_data *__restrict __buffer,
        long int *__restrict __result)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int srand48_r (long int __seedval, struct drand48_data *__buffer)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2)));
extern int seed48_r (unsigned short int __seed16v[3],
       struct drand48_data *__buffer) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern int lcong48_r (unsigned short int __param[7],
        struct drand48_data *__buffer)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2)));
extern void *malloc (size_t __size) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__malloc__)) ;
extern void *calloc (size_t __nmemb, size_t __size)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__malloc__)) ;
extern void *realloc (void *__ptr, size_t __size)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__warn_unused_result__));
extern void free (void *__ptr) __attribute__ ((__nothrow__ , __leaf__));

extern void *alloca (size_t __size) __attribute__ ((__nothrow__ , __leaf__));

extern void *valloc (size_t __size) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__malloc__)) ;
extern int posix_memalign (void **__memptr, size_t __alignment, size_t __size)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1))) ;
extern void *aligned_alloc (size_t __alignment, size_t __size)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__malloc__)) __attribute__ ((__alloc_size__ (2))) ;
extern void abort (void) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__noreturn__));
extern int atexit (void (*__func) (void)) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern int at_quick_exit (void (*__func) (void)) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern int on_exit (void (*__func) (int __status, void *__arg), void *__arg)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern void exit (int __status) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__noreturn__));
extern void quick_exit (int __status) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__noreturn__));
extern void _Exit (int __status) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__noreturn__));
extern char *getenv (const char *__name) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1))) ;
extern int putenv (char *__string) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern int setenv (const char *__name, const char *__value, int __replace)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (2)));
extern int unsetenv (const char *__name) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern int clearenv (void) __attribute__ ((__nothrow__ , __leaf__));
extern char *mktemp (char *__template) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern int mkstemp (char *__template) __asm__ ("" "mkstemp64")
     __attribute__ ((__nonnull__ (1))) ;
extern int mkstemps (char *__template, int __suffixlen) __asm__ ("" "mkstemps64") __attribute__ ((__nonnull__ (1))) ;
extern char *mkdtemp (char *__template) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1))) ;
extern int system (const char *__command) ;
extern char *realpath (const char *__restrict __name,
         char *__restrict __resolved) __attribute__ ((__nothrow__ , __leaf__)) ;
typedef int (*__compar_fn_t) (const void *, const void *);
extern void *bsearch (const void *__key, const void *__base,
        size_t __nmemb, size_t __size, __compar_fn_t __compar)
     __attribute__ ((__nonnull__ (1, 2, 5))) ;
extern void qsort (void *__base, size_t __nmemb, size_t __size,
     __compar_fn_t __compar) __attribute__ ((__nonnull__ (1, 4)));
extern int abs (int __x) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__)) ;
extern long int labs (long int __x) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__)) ;
__extension__ extern long long int llabs (long long int __x)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__)) ;
extern div_t div (int __numer, int __denom)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__)) ;
extern ldiv_t ldiv (long int __numer, long int __denom)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__)) ;
__extension__ extern lldiv_t lldiv (long long int __numer,
        long long int __denom)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__)) ;
extern char *ecvt (double __value, int __ndigit, int *__restrict __decpt,
     int *__restrict __sign) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3, 4))) ;
extern char *fcvt (double __value, int __ndigit, int *__restrict __decpt,
     int *__restrict __sign) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3, 4))) ;
extern char *gcvt (double __value, int __ndigit, char *__buf)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3))) ;
extern char *qecvt (long double __value, int __ndigit,
      int *__restrict __decpt, int *__restrict __sign)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3, 4))) ;
extern char *qfcvt (long double __value, int __ndigit,
      int *__restrict __decpt, int *__restrict __sign)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3, 4))) ;
extern char *qgcvt (long double __value, int __ndigit, char *__buf)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3))) ;
extern int ecvt_r (double __value, int __ndigit, int *__restrict __decpt,
     int *__restrict __sign, char *__restrict __buf,
     size_t __len) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3, 4, 5)));
extern int fcvt_r (double __value, int __ndigit, int *__restrict __decpt,
     int *__restrict __sign, char *__restrict __buf,
     size_t __len) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3, 4, 5)));
extern int qecvt_r (long double __value, int __ndigit,
      int *__restrict __decpt, int *__restrict __sign,
      char *__restrict __buf, size_t __len)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3, 4, 5)));
extern int qfcvt_r (long double __value, int __ndigit,
      int *__restrict __decpt, int *__restrict __sign,
      char *__restrict __buf, size_t __len)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (3, 4, 5)));
extern int mblen (const char *__s, size_t __n) __attribute__ ((__nothrow__ , __leaf__));
extern int mbtowc (wchar_t *__restrict __pwc,
     const char *__restrict __s, size_t __n) __attribute__ ((__nothrow__ , __leaf__));
extern int wctomb (char *__s, wchar_t __wchar) __attribute__ ((__nothrow__ , __leaf__));
extern size_t mbstowcs (wchar_t *__restrict __pwcs,
   const char *__restrict __s, size_t __n) __attribute__ ((__nothrow__ , __leaf__));
extern size_t wcstombs (char *__restrict __s,
   const wchar_t *__restrict __pwcs, size_t __n)
     __attribute__ ((__nothrow__ , __leaf__));
extern int rpmatch (const char *__response) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1))) ;
extern int getsubopt (char **__restrict __optionp,
        char *const *__restrict __tokens,
        char **__restrict __valuep)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1, 2, 3))) ;
extern int getloadavg (double __loadavg[], int __nelem)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));


extern int *__errno_location (void) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__));


struct timezone
  {
    int tz_minuteswest;
    int tz_dsttime;
  };
typedef struct timezone *__restrict __timezone_ptr_t;
extern int gettimeofday (struct timeval *__restrict __tv,
    __timezone_ptr_t __tz) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern int settimeofday (const struct timeval *__tv,
    const struct timezone *__tz)
     __attribute__ ((__nothrow__ , __leaf__));
extern int adjtime (const struct timeval *__delta,
      struct timeval *__olddelta) __attribute__ ((__nothrow__ , __leaf__));
enum __itimer_which
  {
    ITIMER_REAL = 0,
    ITIMER_VIRTUAL = 1,
    ITIMER_PROF = 2
  };
struct itimerval
  {
    struct timeval it_interval;
    struct timeval it_value;
  };
typedef int __itimer_which_t;
extern int getitimer (__itimer_which_t __which,
        struct itimerval *__value) __attribute__ ((__nothrow__ , __leaf__));
extern int setitimer (__itimer_which_t __which,
        const struct itimerval *__restrict __new,
        struct itimerval *__restrict __old) __attribute__ ((__nothrow__ , __leaf__));
extern int utimes (const char *__file, const struct timeval __tvp[2])
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern int lutimes (const char *__file, const struct timeval __tvp[2])
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__nonnull__ (1)));
extern int futimes (int __fd, const struct timeval __tvp[2]) __attribute__ ((__nothrow__ , __leaf__));

typedef __uint8_t uint8_t;
typedef __uint16_t uint16_t;
typedef __uint32_t uint32_t;
typedef __uint64_t uint64_t;
typedef signed char int_least8_t;
typedef short int int_least16_t;
typedef int int_least32_t;
typedef long int int_least64_t;
typedef unsigned char uint_least8_t;
typedef unsigned short int uint_least16_t;
typedef unsigned int uint_least32_t;
typedef unsigned long int uint_least64_t;
typedef signed char int_fast8_t;
typedef long int int_fast16_t;
typedef long int int_fast32_t;
typedef long int int_fast64_t;
typedef unsigned char uint_fast8_t;
typedef unsigned long int uint_fast16_t;
typedef unsigned long int uint_fast32_t;
typedef unsigned long int uint_fast64_t;
typedef long int intptr_t;
typedef unsigned long int uintptr_t;
typedef __intmax_t intmax_t;
typedef __uintmax_t uintmax_t;
typedef int __gwchar_t;

typedef struct
  {
    long int quot;
    long int rem;
  } imaxdiv_t;
extern intmax_t imaxabs (intmax_t __n) __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__));
extern imaxdiv_t imaxdiv (intmax_t __numer, intmax_t __denom)
      __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__));
extern intmax_t strtoimax (const char *__restrict __nptr,
      char **__restrict __endptr, int __base) __attribute__ ((__nothrow__ , __leaf__));
extern uintmax_t strtoumax (const char *__restrict __nptr,
       char ** __restrict __endptr, int __base) __attribute__ ((__nothrow__ , __leaf__));
extern intmax_t wcstoimax (const __gwchar_t *__restrict __nptr,
      __gwchar_t **__restrict __endptr, int __base)
     __attribute__ ((__nothrow__ , __leaf__));
extern uintmax_t wcstoumax (const __gwchar_t *__restrict __nptr,
       __gwchar_t ** __restrict __endptr, int __base)
     __attribute__ ((__nothrow__ , __leaf__));

enum LibRaw_openbayer_patterns
{
  LIBRAW_OPENBAYER_RGGB = 0x94,
  LIBRAW_OPENBAYER_BGGR = 0x16,
  LIBRAW_OPENBAYER_GRBG = 0x61,
  LIBRAW_OPENBAYER_GBRG = 0x49
};
enum LibRaw_dngfields_marks
{
  LIBRAW_DNGFM_FORWARDMATRIX = 1,
  LIBRAW_DNGFM_ILLUMINANT = 2,
  LIBRAW_DNGFM_COLORMATRIX = 4,
  LIBRAW_DNGFM_CALIBRATION = 8,
  LIBRAW_DNGFM_ANALOGBALANCE = 16,
  LIBRAW_DNGFM_BLACK = 32,
  LIBRAW_DNGFM_WHITE = 64,
  LIBRAW_DNGFM_OPCODE2 = 128,
  LIBRAW_DNGFM_LINTABLE = 256,
  LIBRAW_DNGFM_CROPORIGIN = 512,
  LIBRAW_DNGFM_CROPSIZE = 1024,
  LIBRAW_DNGFM_PREVIEWCS = 2048
};
enum LibRaw_whitebalance_code
{
  LIBRAW_WBI_Unknown = 0,
  LIBRAW_WBI_Daylight = 1,
  LIBRAW_WBI_Fluorescent = 2,
  LIBRAW_WBI_Tungsten = 3,
  LIBRAW_WBI_Flash = 4,
  LIBRAW_WBI_FineWeather = 9,
  LIBRAW_WBI_Cloudy = 10,
  LIBRAW_WBI_Shade = 11,
  LIBRAW_WBI_FL_D = 12,
  LIBRAW_WBI_FL_N = 13,
  LIBRAW_WBI_FL_W = 14,
  LIBRAW_WBI_FL_WW = 15,
  LIBRAW_WBI_FL_L = 16,
  LIBRAW_WBI_Ill_A = 17,
  LIBRAW_WBI_Ill_B = 18,
  LIBRAW_WBI_Ill_C = 19,
  LIBRAW_WBI_D55 = 20,
  LIBRAW_WBI_D65 = 21,
  LIBRAW_WBI_D75 = 22,
  LIBRAW_WBI_D50 = 23,
  LIBRAW_WBI_StudioTungsten = 24,
  LIBRAW_WBI_Sunset = 64,
  LIBRAW_WBI_Auto = 82,
  LIBRAW_WBI_Custom = 83,
  LIBRAW_WBI_Auto1 = 85,
  LIBRAW_WBI_Auto2 = 86,
  LIBRAW_WBI_Auto3 = 87,
  LIBRAW_WBI_Auto4 = 88,
  LIBRAW_WBI_Custom1 = 90,
  LIBRAW_WBI_Custom2 = 91,
  LIBRAW_WBI_Custom3 = 92,
  LIBRAW_WBI_Custom4 = 93,
  LIBRAW_WBI_Custom5 = 94,
  LIBRAW_WBI_Custom6 = 95,
  LIBRAW_WBI_Measured = 100,
  LIBRAW_WBI_Underwater = 120,
  LIBRAW_WBI_Other = 255
};
enum LibRaw_MultiExposure_related
{
  LIBRAW_ME_NONE = 0,
  LIBRAW_ME_SIMPLE = 1,
  LIBRAW_ME_OVERLAY = 2,
  LIBRAW_ME_HDR = 3
};
enum LibRaw_dng_processing
{
  LIBRAW_DNG_NONE = 0,
  LIBRAW_DNG_FLOAT = 1,
  LIBRAW_DNG_LINEAR = 2,
  LIBRAW_DNG_DEFLATE = 4,
  LIBRAW_DNG_XTRANS = 8,
  LIBRAW_DNG_OTHER = 16,
  LIBRAW_DNG_8BIT = 32,
  LIBRAW_DNG_ALL = LIBRAW_DNG_FLOAT | LIBRAW_DNG_LINEAR | LIBRAW_DNG_XTRANS | LIBRAW_DNG_8BIT |
                   LIBRAW_DNG_OTHER ,
  LIBRAW_DNG_DEFAULT = LIBRAW_DNG_FLOAT | LIBRAW_DNG_LINEAR | LIBRAW_DNG_DEFLATE | LIBRAW_DNG_8BIT
};
enum LibRaw_runtime_capabilities
{
  LIBRAW_CAPS_RAWSPEED = 1,
  LIBRAW_CAPS_DNGSDK = 2
};
enum LibRaw_camera_mounts
{
  LIBRAW_MOUNT_Unknown = 0,
  LIBRAW_MOUNT_Minolta_A = 1,
  LIBRAW_MOUNT_Sony_E = 2,
  LIBRAW_MOUNT_Canon_EF = 3,
  LIBRAW_MOUNT_Canon_EF_S = 4,
  LIBRAW_MOUNT_Canon_EF_M = 5,
  LIBRAW_MOUNT_Nikon_F = 6,
  LIBRAW_MOUNT_Nikon_CX = 7,
  LIBRAW_MOUNT_FT = 8,
  LIBRAW_MOUNT_mFT = 9,
  LIBRAW_MOUNT_Pentax_K = 10,
  LIBRAW_MOUNT_Pentax_Q = 11,
  LIBRAW_MOUNT_Pentax_645 = 12,
  LIBRAW_MOUNT_Fuji_X = 13,
  LIBRAW_MOUNT_Leica_M = 14,
  LIBRAW_MOUNT_Leica_R = 15,
  LIBRAW_MOUNT_Leica_S = 16,
  LIBRAW_MOUNT_Samsung_NX = 17,
  LIBRAW_MOUNT_RicohModule = 18,
  LIBRAW_MOUNT_Samsung_NX_M = 19,
  LIBRAW_MOUNT_Leica_T = 20,
  LIBRAW_MOUNT_Contax_N = 21,
  LIBRAW_MOUNT_Sigma_X3F = 22,
  LIBRAW_MOUNT_Leica_SL = 23,
  LIBRAW_MOUNT_FixedLens = 99
};
enum LibRaw_camera_formats
{
  LIBRAW_FORMAT_APSC = 1,
  LIBRAW_FORMAT_FF = 2,
  LIBRAW_FORMAT_MF = 3,
  LIBRAW_FORMAT_APSH = 4,
  LIBRAW_FORMAT_1INCH = 5,
  LIBRAW_FORMAT_FT = 8
};
enum LibRaw_sony_cameratypes
{
  LIBRAW_SONY_DSC = 1,
  LIBRAW_SONY_DSLR = 2,
  LIBRAW_SONY_NEX = 3,
  LIBRAW_SONY_SLT = 4,
  LIBRAW_SONY_ILCE = 5,
  LIBRAW_SONY_ILCA = 6
};
enum LibRaw_processing_options
{
  LIBRAW_PROCESSING_SONYARW2_NONE = 0,
  LIBRAW_PROCESSING_SONYARW2_BASEONLY = 1,
  LIBRAW_PROCESSING_SONYARW2_DELTAONLY = 1 << 1,
  LIBRAW_PROCESSING_SONYARW2_DELTAZEROBASE = 1 << 2,
  LIBRAW_PROCESSING_SONYARW2_DELTATOVALUE = 1 << 3,
  LIBRAW_PROCESSING_SONYARW2_ALLFLAGS = LIBRAW_PROCESSING_SONYARW2_BASEONLY + LIBRAW_PROCESSING_SONYARW2_DELTAONLY +
                                        LIBRAW_PROCESSING_SONYARW2_DELTAZEROBASE +
                                        LIBRAW_PROCESSING_SONYARW2_DELTATOVALUE,
  LIBRAW_PROCESSING_DP2Q_INTERPOLATERG = 1 << 4,
  LIBRAW_PROCESSING_DP2Q_INTERPOLATEAF = 1 << 5,
  LIBRAW_PROCESSING_PENTAX_PS_ALLFRAMES = 1 << 6,
  LIBRAW_PROCESSING_CONVERTFLOAT_TO_INT = 1 << 7,
  LIBRAW_PROCESSING_SRAW_NO_RGB = 1 << 8,
  LIBRAW_PROCESSING_SRAW_NO_INTERPOLATE = 1 << 9,
  LIBRAW_PROCESSING_NO_ROTATE_FOR_KODAK_THUMBNAILS = 1 << 11,
  LIBRAW_PROCESSING_USE_DNG_DEFAULT_CROP = 1 << 12,
  LIBRAW_PROCESSING_USE_PPM16_THUMBS = 1 << 13,
  LIBRAW_PROCESSING_CHECK_DNG_ILLUMINANT = 1 << 15
};
enum LibRaw_decoder_flags
{
  LIBRAW_DECODER_HASCURVE = 1 << 4,
  LIBRAW_DECODER_SONYARW2 = 1 << 5,
  LIBRAW_DECODER_TRYRAWSPEED = 1 << 6,
  LIBRAW_DECODER_OWNALLOC = 1 << 7,
  LIBRAW_DECODER_FIXEDMAXC = 1 << 8,
  LIBRAW_DECODER_ADOBECOPYPIXEL = 1 << 9,
  LIBRAW_DECODER_LEGACY_WITH_MARGINS = 1 << 10,
  LIBRAW_DECODER_3CHANNEL = 1 << 11,
  LIBRAW_DECODER_SINAR4SHOT = 1 << 11,
  LIBRAW_DECODER_NOTSET = 1 << 15
};
enum LibRaw_constructor_flags
{
  LIBRAW_OPTIONS_NONE = 0,
  LIBRAW_OPIONS_NO_MEMERR_CALLBACK = 1,
  LIBRAW_OPIONS_NO_DATAERR_CALLBACK = 1 << 1
};
enum LibRaw_warnings
{
  LIBRAW_WARN_NONE = 0,
  LIBRAW_WARN_BAD_CAMERA_WB = 1 << 2,
  LIBRAW_WARN_NO_METADATA = 1 << 3,
  LIBRAW_WARN_NO_JPEGLIB = 1 << 4,
  LIBRAW_WARN_NO_EMBEDDED_PROFILE = 1 << 5,
  LIBRAW_WARN_NO_INPUT_PROFILE = 1 << 6,
  LIBRAW_WARN_BAD_OUTPUT_PROFILE = 1 << 7,
  LIBRAW_WARN_NO_BADPIXELMAP = 1 << 8,
  LIBRAW_WARN_BAD_DARKFRAME_FILE = 1 << 9,
  LIBRAW_WARN_BAD_DARKFRAME_DIM = 1 << 10,
  LIBRAW_WARN_NO_JASPER = 1 << 11,
  LIBRAW_WARN_RAWSPEED_PROBLEM = 1 << 12,
  LIBRAW_WARN_RAWSPEED_UNSUPPORTED = 1 << 13,
  LIBRAW_WARN_RAWSPEED_PROCESSED = 1 << 14,
  LIBRAW_WARN_FALLBACK_TO_AHD = 1 << 15,
  LIBRAW_WARN_PARSEFUJI_PROCESSED = 1 << 16
};
enum LibRaw_exceptions
{
  LIBRAW_EXCEPTION_NONE = 0,
  LIBRAW_EXCEPTION_ALLOC = 1,
  LIBRAW_EXCEPTION_DECODE_RAW = 2,
  LIBRAW_EXCEPTION_DECODE_JPEG = 3,
  LIBRAW_EXCEPTION_IO_EOF = 4,
  LIBRAW_EXCEPTION_IO_CORRUPT = 5,
  LIBRAW_EXCEPTION_CANCELLED_BY_CALLBACK = 6,
  LIBRAW_EXCEPTION_BAD_CROP = 7,
  LIBRAW_EXCEPTION_IO_BADFILE = 8,
  LIBRAW_EXCEPTION_DECODE_JPEG2000 = 9,
  LIBRAW_EXCEPTION_TOOBIG = 10,
  LIBRAW_EXCEPTION_MEMPOOL = 11
};
enum LibRaw_progress
{
  LIBRAW_PROGRESS_START = 0,
  LIBRAW_PROGRESS_OPEN = 1,
  LIBRAW_PROGRESS_IDENTIFY = 1 << 1,
  LIBRAW_PROGRESS_SIZE_ADJUST = 1 << 2,
  LIBRAW_PROGRESS_LOAD_RAW = 1 << 3,
  LIBRAW_PROGRESS_RAW2_IMAGE = 1 << 4,
  LIBRAW_PROGRESS_REMOVE_ZEROES = 1 << 5,
  LIBRAW_PROGRESS_BAD_PIXELS = 1 << 6,
  LIBRAW_PROGRESS_DARK_FRAME = 1 << 7,
  LIBRAW_PROGRESS_FOVEON_INTERPOLATE = 1 << 8,
  LIBRAW_PROGRESS_SCALE_COLORS = 1 << 9,
  LIBRAW_PROGRESS_PRE_INTERPOLATE = 1 << 10,
  LIBRAW_PROGRESS_INTERPOLATE = 1 << 11,
  LIBRAW_PROGRESS_MIX_GREEN = 1 << 12,
  LIBRAW_PROGRESS_MEDIAN_FILTER = 1 << 13,
  LIBRAW_PROGRESS_HIGHLIGHTS = 1 << 14,
  LIBRAW_PROGRESS_FUJI_ROTATE = 1 << 15,
  LIBRAW_PROGRESS_FLIP = 1 << 16,
  LIBRAW_PROGRESS_APPLY_PROFILE = 1 << 17,
  LIBRAW_PROGRESS_CONVERT_RGB = 1 << 18,
  LIBRAW_PROGRESS_STRETCH = 1 << 19,
  LIBRAW_PROGRESS_STAGE20 = 1 << 20,
  LIBRAW_PROGRESS_STAGE21 = 1 << 21,
  LIBRAW_PROGRESS_STAGE22 = 1 << 22,
  LIBRAW_PROGRESS_STAGE23 = 1 << 23,
  LIBRAW_PROGRESS_STAGE24 = 1 << 24,
  LIBRAW_PROGRESS_STAGE25 = 1 << 25,
  LIBRAW_PROGRESS_STAGE26 = 1 << 26,
  LIBRAW_PROGRESS_STAGE27 = 1 << 27,
  LIBRAW_PROGRESS_THUMB_LOAD = 1 << 28,
  LIBRAW_PROGRESS_TRESERVED1 = 1 << 29,
  LIBRAW_PROGRESS_TRESERVED2 = 1 << 30,
  LIBRAW_PROGRESS_TRESERVED3 = 1 << 31
};
enum LibRaw_errors
{
  LIBRAW_SUCCESS = 0,
  LIBRAW_UNSPECIFIED_ERROR = -1,
  LIBRAW_FILE_UNSUPPORTED = -2,
  LIBRAW_REQUEST_FOR_NONEXISTENT_IMAGE = -3,
  LIBRAW_OUT_OF_ORDER_CALL = -4,
  LIBRAW_NO_THUMBNAIL = -5,
  LIBRAW_UNSUPPORTED_THUMBNAIL = -6,
  LIBRAW_INPUT_CLOSED = -7,
  LIBRAW_NOT_IMPLEMENTED = -8,
  LIBRAW_UNSUFFICIENT_MEMORY = -100007,
  LIBRAW_DATA_ERROR = -100008,
  LIBRAW_IO_ERROR = -100009,
  LIBRAW_CANCELLED_BY_CALLBACK = -100010,
  LIBRAW_BAD_CROP = -100011,
  LIBRAW_TOO_BIG = -100012,
  LIBRAW_MEMPOOL_OVERFLOW = -100013
};
enum LibRaw_thumbnail_formats
{
  LIBRAW_THUMBNAIL_UNKNOWN = 0,
  LIBRAW_THUMBNAIL_JPEG = 1,
  LIBRAW_THUMBNAIL_BITMAP = 2,
  LIBRAW_THUMBNAIL_BITMAP16 = 3,
  LIBRAW_THUMBNAIL_LAYER = 4,
  LIBRAW_THUMBNAIL_ROLLEI = 5
};
enum LibRaw_image_formats
{
  LIBRAW_IMAGE_JPEG = 1,
  LIBRAW_IMAGE_BITMAP = 2
};
typedef long long INT64;
typedef unsigned long long UINT64;
  typedef unsigned char uchar;
  typedef unsigned short ushort;
  typedef struct
  {
    const char *decoder_name;
    unsigned decoder_flags;
  } libraw_decoder_info_t;
  typedef struct
  {
    unsigned mix_green;
    unsigned raw_color;
    unsigned zero_is_bad;
    ushort shrink;
    ushort fuji_width;
  } libraw_internal_output_params_t;
  typedef void (*memory_callback)(void *data, const char *file, const char *where);
  typedef void (*exif_parser_callback)(void *context, int tag, int type, int len, unsigned int ord, void *ifp);
  void default_memory_callback(void *data, const char *file, const char *where);
  typedef void (*data_callback)(void *data, const char *file, const int offset);
  void default_data_callback(void *data, const char *file, const int offset);
  typedef int (*progress_callback)(void *data, enum LibRaw_progress stage, int iteration, int expected);
  typedef int (*pre_identify_callback)(void *ctx);
  typedef void (*post_identify_callback)(void *ctx);
  typedef void (*process_step_callback)(void *ctx);
  typedef struct
  {
    memory_callback mem_cb;
    void *memcb_data;
    data_callback data_cb;
    void *datacb_data;
    progress_callback progress_cb;
    void *progresscb_data;
    exif_parser_callback exif_cb;
    void *exifparser_data;
    pre_identify_callback pre_identify_cb;
    post_identify_callback post_identify_cb;
    process_step_callback pre_subtractblack_cb, pre_scalecolors_cb, pre_preinterpolate_cb, pre_interpolate_cb,
   interpolate_bayer_cb, interpolate_xtrans_cb,
        post_interpolate_cb, pre_converttorgb_cb, post_converttorgb_cb;
  } libraw_callbacks_t;
  typedef struct
  {
    enum LibRaw_image_formats type;
    ushort height, width, colors, bits;
    unsigned int data_size;
    unsigned char data[1];
  } libraw_processed_image_t;
  typedef struct
  {
    char guard[4];
    char make[64];
    char model[64];
    char software[64];
    unsigned raw_count;
    unsigned dng_version;
    unsigned is_foveon;
    int colors;
    unsigned filters;
    char xtrans[6][6];
    char xtrans_abs[6][6];
    char cdesc[5];
    unsigned xmplen;
    char *xmpdata;
  } libraw_iparams_t;
  typedef struct
  {
    ushort cleft, ctop, cwidth, cheight;
  } libraw_raw_crop_t;
  typedef struct
  {
    ushort raw_height, raw_width, height, width, top_margin, left_margin;
    ushort iheight, iwidth;
    unsigned raw_pitch;
    double pixel_aspect;
    int flip;
    int mask[8][4];
    libraw_raw_crop_t raw_crop;
  } libraw_image_sizes_t;
  struct ph1_t
  {
    int format, key_off, tag_21a;
    int t_black, split_col, black_col, split_row, black_row;
    float tag_210;
  };
  typedef struct
  {
    unsigned parsedfields;
    ushort illuminant;
    float calibration[4][4];
    float colormatrix[4][3];
    float forwardmatrix[3][4];
  } libraw_dng_color_t;
  typedef struct
  {
    unsigned parsedfields;
    unsigned dng_cblack[4102];
    unsigned dng_black;
    unsigned dng_whitelevel[4];
    unsigned default_crop[4];
    unsigned preview_colorspace;
    float analogbalance[4];
  } libraw_dng_levels_t;
  typedef struct
  {
    float romm_cam[9];
  } libraw_P1_color_t;
  typedef struct
  {
    int CanonColorDataVer;
    int CanonColorDataSubVer;
    int SpecularWhiteLevel;
    int NormalWhiteLevel;
    int ChannelBlackLevel[4];
    int AverageBlackLevel;
    unsigned int multishot[4];
    short MeteringMode;
    short SpotMeteringMode;
    uchar FlashMeteringMode;
    short FlashExposureLock;
    short ExposureMode;
    short AESetting;
    uchar HighlightTonePriority;
    short ImageStabilization;
    short FocusMode;
    short AFPoint;
    short FocusContinuous;
    short AFPointsInFocus30D;
    uchar AFPointsInFocus1D[8];
    ushort AFPointsInFocus5D;
    ushort AFAreaMode;
    ushort NumAFPoints;
    ushort ValidAFPoints;
    ushort AFImageWidth;
    ushort AFImageHeight;
    short AFAreaWidths[61];
    short AFAreaHeights[61];
    short AFAreaXPositions[61];
    short AFAreaYPositions[61];
    short AFPointsInFocus[4];
    short AFPointsSelected[4];
    ushort PrimaryAFPoint;
    short FlashMode;
    short FlashActivity;
    short FlashBits;
    short ManualFlashOutput;
    short FlashOutput;
    short FlashGuideNumber;
    short ContinuousDrive;
    short SensorWidth;
    short SensorHeight;
    short SensorLeftBorder;
    short SensorTopBorder;
    short SensorRightBorder;
    short SensorBottomBorder;
    short BlackMaskLeftBorder;
    short BlackMaskTopBorder;
    short BlackMaskRightBorder;
    short BlackMaskBottomBorder;
    int AFMicroAdjMode;
    float AFMicroAdjValue;
  } libraw_canon_makernotes_t;
  typedef struct
  {
    int BaseISO;
    double Gain;
  } libraw_hasselblad_makernotes_t;
  typedef struct
  {
    float FujiExpoMidPointShift;
    ushort FujiDynamicRange;
    ushort FujiFilmMode;
    ushort FujiDynamicRangeSetting;
    ushort FujiDevelopmentDynamicRange;
    ushort FujiAutoDynamicRange;
    ushort FocusMode;
    ushort AFMode;
    ushort FocusPixel[2];
    ushort ImageStabilization[3];
    ushort FlashMode;
    ushort WB_Preset;
    ushort ShutterType;
    ushort ExrMode;
    ushort Macro;
    unsigned Rating;
    ushort FrameRate;
    ushort FrameWidth;
    ushort FrameHeight;
  } libraw_fuji_info_t;
  typedef struct
  {
    double ExposureBracketValue;
    ushort ActiveDLighting;
    ushort ShootingMode;
    uchar ImageStabilization[7];
    uchar VibrationReduction;
    uchar VRMode;
    char FocusMode[7];
    uchar AFPoint;
    ushort AFPointsInFocus;
    uchar ContrastDetectAF;
    uchar AFAreaMode;
    uchar PhaseDetectAF;
    uchar PrimaryAFPoint;
    uchar AFPointsUsed[29];
    ushort AFImageWidth;
    ushort AFImageHeight;
    ushort AFAreaXPposition;
    ushort AFAreaYPosition;
    ushort AFAreaWidth;
    ushort AFAreaHeight;
    uchar ContrastDetectAFInFocus;
    char FlashSetting[13];
    char FlashType[20];
    uchar FlashExposureCompensation[4];
    uchar ExternalFlashExposureComp[4];
    uchar FlashExposureBracketValue[4];
    uchar FlashMode;
    signed char FlashExposureCompensation2;
    signed char FlashExposureCompensation3;
    signed char FlashExposureCompensation4;
    uchar FlashSource;
    uchar FlashFirmware[2];
    uchar ExternalFlashFlags;
    uchar FlashControlCommanderMode;
    uchar FlashOutputAndCompensation;
    uchar FlashFocalLength;
    uchar FlashGNDistance;
    uchar FlashGroupControlMode[4];
    uchar FlashGroupOutputAndCompensation[4];
    uchar FlashColorFilter;
    ushort NEFCompression;
    int ExposureMode;
    int nMEshots;
    int MEgainOn;
    double ME_WB[4];
    uchar AFFineTune;
    uchar AFFineTuneIndex;
    int8_t AFFineTuneAdj;
  } libraw_nikon_makernotes_t;
  typedef struct
  {
    int OlympusCropID;
    ushort OlympusFrame[4];
    int OlympusSensorCalibration[2];
    ushort FocusMode[2];
    ushort AutoFocus;
    ushort AFPoint;
    unsigned AFAreas[64];
    double AFPointSelected[5];
    ushort AFResult;
    unsigned ImageStabilization;
    ushort ColorSpace;
    uchar AFFineTune;
    short AFFineTuneAdj[3];
  } libraw_olympus_makernotes_t;
  typedef struct
  {
    ushort Compression;
    ushort BlackLevelDim;
    float BlackLevel[8];
  } libraw_panasonic_makernotes_t;
  typedef struct
  {
    ushort FocusMode;
    ushort AFPointSelected;
    unsigned AFPointsInFocus;
    ushort FocusPosition;
    uchar DriveMode[4];
    short AFAdjustment;
  } libraw_pentax_makernotes_t;
  typedef struct
  {
    ushort BlackLevelTop;
    ushort BlackLevelBottom;
    short offset_left, offset_top;
    ushort clipBlack, clipWhite;
    float romm_camDaylight[3][3];
    float romm_camTungsten[3][3];
    float romm_camFluorescent[3][3];
    float romm_camFlash[3][3];
    float romm_camCustom[3][3];
    float romm_camAuto[3][3];
  } libraw_kodak_makernotes_t;
  typedef struct
  {
    ushort SonyCameraType;
    uchar Sony0x9400_version;
    uchar Sony0x9400_ReleaseMode2;
    unsigned Sony0x9400_SequenceImageNumber;
    uchar Sony0x9400_SequenceLength1;
    unsigned Sony0x9400_SequenceFileNumber;
    uchar Sony0x9400_SequenceLength2;
    libraw_raw_crop_t raw_crop;
    int8_t AFMicroAdjValue;
    int8_t AFMicroAdjOn;
    uchar AFMicroAdjRegisteredLenses;
    ushort group2010;
    ushort real_iso_offset;
    float firmware;
    ushort ImageCount3_offset;
    unsigned ImageCount3;
    unsigned ElectronicFrontCurtainShutter;
    ushort MeteringMode2;
    char SonyDateTime[20];
    uchar TimeStamp[6];
    unsigned ShotNumberSincePowerUp;
  } libraw_sony_info_t;
  typedef struct
  {
    ushort curve[0x10000];
    unsigned cblack[4102];
    unsigned black;
    unsigned data_maximum;
    unsigned maximum;
    long linear_max[4];
    float fmaximum;
    float fnorm;
    ushort white[8][8];
    float cam_mul[4];
    float pre_mul[4];
    float cmatrix[3][4];
    float ccm[3][4];
    float rgb_cam[3][4];
    float cam_xyz[4][3];
    struct ph1_t phase_one_data;
    float flash_used;
    float canon_ev;
    char model2[64];
    char UniqueCameraModel[64];
    char LocalizedCameraModel[64];
    void *profile;
    unsigned profile_length;
    unsigned black_stat[8];
    libraw_dng_color_t dng_color[2];
    libraw_dng_levels_t dng_levels;
    float baseline_exposure;
    int WB_Coeffs[256][4];
    float WBCT_Coeffs[64][5];
    libraw_P1_color_t P1_color[2];
  } libraw_colordata_t;
  typedef struct
  {
    enum LibRaw_thumbnail_formats tformat;
    ushort twidth, theight;
    unsigned tlength;
    int tcolors;
    char *thumb;
  } libraw_thumbnail_t;
  typedef struct
  {
    float latitude[3];
    float longtitude[3];
    float gpstimestamp[3];
    float altitude;
    char altref, latref, longref, gpsstatus;
    char gpsparsed;
  } libraw_gps_info_t;
  typedef struct
  {
    float iso_speed;
    float shutter;
    float aperture;
    float focal_len;
    time_t timestamp;
    unsigned shot_order;
    unsigned gpsdata[32];
    libraw_gps_info_t parsed_gps;
    char desc[512], artist[64];
    float FlashEC;
    float FlashGN;
    float CameraTemperature;
    float SensorTemperature;
    float SensorTemperature2;
    float LensTemperature;
    float AmbientTemperature;
    float BatteryTemperature;
    float exifAmbientTemperature;
    float exifHumidity;
    float exifPressure;
    float exifWaterDepth;
    float exifAcceleration;
    float exifCameraElevationAngle;
    float real_ISO;
  } libraw_imgother_t;
  typedef struct
  {
    unsigned greybox[4];
    unsigned cropbox[4];
    double aber[4];
    double gamm[6];
    float user_mul[4];
    unsigned shot_select;
    float bright;
    float threshold;
    int half_size;
    int four_color_rgb;
    int highlight;
    int use_auto_wb;
    int use_camera_wb;
    int use_camera_matrix;
    int output_color;
    char *output_profile;
    char *camera_profile;
    char *bad_pixels;
    char *dark_frame;
    int output_bps;
    int output_tiff;
    int user_flip;
    int user_qual;
    int user_black;
    int user_cblack[4];
    int user_sat;
    int med_passes;
    float auto_bright_thr;
    float adjust_maximum_thr;
    int no_auto_bright;
    int use_fuji_rotate;
    int green_matching;
    int dcb_iterations;
    int dcb_enhance_fl;
    int fbdd_noiserd;
    int exp_correc;
    float exp_shift;
    float exp_preser;
    int use_rawspeed;
    int use_dngsdk;
    int no_auto_scale;
    int no_interpolation;
    unsigned raw_processing_options;
    int sony_arw2_posterization_thr;
    float coolscan_nef_gamma;
    char p4shot_order[5];
    char **custom_camera_strings;
  } libraw_output_params_t;
  typedef struct
  {
    void *raw_alloc;
    ushort *raw_image;
    ushort (*color4_image)[4];
    ushort (*color3_image)[3];
    float *float_image;
    float (*float3_image)[3];
    float (*float4_image)[4];
    short (*ph1_cblack)[2];
    short (*ph1_rblack)[2];
    libraw_iparams_t iparams;
    libraw_image_sizes_t sizes;
    libraw_internal_output_params_t ioparams;
    libraw_colordata_t color;
  } libraw_rawdata_t;
  typedef struct
  {
    unsigned long long LensID;
    char Lens[128];
    ushort LensFormat;
    ushort LensMount;
    unsigned long long CamID;
    ushort CameraFormat;
    ushort CameraMount;
    char body[64];
    short FocalType;
    char LensFeatures_pre[16], LensFeatures_suf[16];
    float MinFocal, MaxFocal;
    float MaxAp4MinFocal, MaxAp4MaxFocal, MinAp4MinFocal, MinAp4MaxFocal;
    float MaxAp, MinAp;
    float CurFocal, CurAp;
    float MaxAp4CurFocal, MinAp4CurFocal;
    float MinFocusDistance;
    float FocusRangeIndex;
    float LensFStops;
    unsigned long long TeleconverterID;
    char Teleconverter[128];
    unsigned long long AdapterID;
    char Adapter[128];
    unsigned long long AttachmentID;
    char Attachment[128];
    ushort CanonFocalUnits;
    float FocalLengthIn35mmFormat;
  } libraw_makernotes_lens_t;
  typedef struct
  {
    float NikonEffectiveMaxAp;
    uchar NikonLensIDNumber, NikonLensFStops, NikonMCUVersion, NikonLensType;
  } libraw_nikonlens_t;
  typedef struct
  {
    float MinFocal, MaxFocal, MaxAp4MinFocal, MaxAp4MaxFocal;
  } libraw_dnglens_t;
  typedef struct
  {
    float MinFocal, MaxFocal, MaxAp4MinFocal, MaxAp4MaxFocal, EXIF_MaxAp;
    char LensMake[128], Lens[128], LensSerial[128], InternalLensSerial[128];
    ushort FocalLengthIn35mmFormat;
    libraw_nikonlens_t nikon;
    libraw_dnglens_t dng;
    libraw_makernotes_lens_t makernotes;
  } libraw_lensinfo_t;
  typedef struct
  {
    libraw_canon_makernotes_t canon;
    libraw_nikon_makernotes_t nikon;
    libraw_hasselblad_makernotes_t hasselblad;
    libraw_fuji_info_t fuji;
    libraw_olympus_makernotes_t olympus;
    libraw_sony_info_t sony;
    libraw_kodak_makernotes_t kodak;
    libraw_panasonic_makernotes_t panasonic;
    libraw_pentax_makernotes_t pentax;
  } libraw_makernotes_t;
  typedef struct
  {
    short DriveMode;
    short FocusMode;
    short MeteringMode;
    short AFPoint;
    short ExposureMode;
    short ImageStabilization;
    char BodySerial[64];
    char InternalBodySerial[64];
  } libraw_shootinginfo_t;
  typedef struct
  {
    unsigned fsize;
    ushort rw, rh;
    uchar lm, tm, rm, bm, lf, cf, max, flags;
    char t_make[10], t_model[20];
    ushort offset;
  } libraw_custom_camera_t;
  typedef struct
  {
    ushort (*image)[4];
    libraw_image_sizes_t sizes;
    libraw_iparams_t idata;
    libraw_lensinfo_t lens;
    libraw_makernotes_t makernotes;
    libraw_shootinginfo_t shootinginfo;
    libraw_output_params_t params;
    unsigned int progress_flags;
    unsigned int process_warnings;
    libraw_colordata_t color;
    libraw_imgother_t other;
    libraw_thumbnail_t thumbnail;
    libraw_rawdata_t rawdata;
    void *parent_class;
  } libraw_data_t;
  struct fuji_compressed_params
  {
    int8_t *q_table;
    int q_point[5];
    int max_bits;
    int min_value;
    int raw_bits;
    int total_values;
    int maxDiff;
    ushort line_width;
  };
typedef struct
{
  struct
      LibRaw_abstract_datastream *input;
  FILE *output;
  int input_internal;
  char *meta_data;
  INT64 profile_offset;
  INT64 toffset;
  unsigned pana_black[4];
} internal_data_t;
typedef struct
{
  int (*histogram)[0x2000];
  unsigned *oprof;
} output_data_t;
typedef struct
{
  unsigned olympus_exif_cfa;
  unsigned unique_id;
  unsigned long long OlyID;
  unsigned tiff_nifds;
  int tiff_flip;
} identify_data_t;
typedef struct
{
  short order;
  ushort sraw_mul[4], cr2_slice[3];
  unsigned kodak_cbpp;
  INT64 strip_offset, data_offset;
  INT64 meta_offset;
  unsigned data_size;
  unsigned meta_length;
  unsigned thumb_misc;
  unsigned fuji_layout;
  unsigned tiff_samples;
  unsigned tiff_bps;
  unsigned tiff_compress;
  unsigned zero_after_ff;
  unsigned tile_width, tile_length, load_flags;
  unsigned data_error;
  int hasselblad_parser_flag;
  long long posRAFData;
  unsigned lenRAFData;
  int fuji_total_lines, fuji_total_blocks, fuji_block_width, fuji_bits, fuji_raw_type;
 int pana_encoding, pana_bpp;
} unpacker_data_t;
typedef struct
{
  internal_data_t internal_data;
  libraw_internal_output_params_t internal_output_params;
  output_data_t output_data;
  identify_data_t identify_data;
  unpacker_data_t unpacker_data;
} libraw_internal_data_t;
struct decode
{
  struct decode *branch[2];
  int leaf;
};
struct tiff_ifd_t
{
  int t_width, t_height, bps, comp, phint, offset, t_flip, samples, bytes;
  int t_tile_width, t_tile_length, sample_format, predictor;
  int rows_per_strip;
  int *strip_offsets, strip_offsets_count;
  int *strip_byte_counts, strip_byte_counts_count;
  float t_shutter;
  INT64 opcode2_offset;
  INT64 lineartable_offset;
  int lineartable_len;
  libraw_dng_color_t dng_color[2];
  libraw_dng_levels_t dng_levels;
};
struct jhead
{
  int algo, bits, high, wide, clrs, sraw, psv, restart, vpred[6];
  ushort quant[64], idct[64], *huff[20], *free[20], *row;
};
struct libraw_tiff_tag
{
  ushort tag, type;
  int count;
  union {
    char c[4];
    short s[2];
    int i;
  } val;
};
struct tiff_hdr
{
  ushort t_order, magic;
  int ifd;
  ushort pad, ntag;
  struct libraw_tiff_tag tag[23];
  int nextifd;
  ushort pad2, nexif;
  struct libraw_tiff_tag exif[4];
  ushort pad3, ngps;
  struct libraw_tiff_tag gpst[10];
  short bps[4];
  int rat[10];
  unsigned gps[26];
  char t_desc[512], t_make[64], t_model[64], soft[32], date[20], t_artist[64];
};
  const char *libraw_strerror(int errorcode);
  const char *libraw_strprogress(enum LibRaw_progress);
  libraw_data_t *libraw_init(unsigned int flags);
  int libraw_open_file(libraw_data_t *, const char *);
  int libraw_open_file_ex(libraw_data_t *, const char *, INT64 max_buff_sz);
  int libraw_open_buffer(libraw_data_t *, void *buffer, size_t size);
  int libraw_unpack(libraw_data_t *);
  int libraw_unpack_thumb(libraw_data_t *);
  void libraw_recycle_datastream(libraw_data_t *);
  void libraw_recycle(libraw_data_t *);
  void libraw_close(libraw_data_t *);
  void libraw_subtract_black(libraw_data_t *);
  int libraw_raw2image(libraw_data_t *);
  void libraw_free_image(libraw_data_t *);
  const char *libraw_version();
  int libraw_versionNumber();
  const char **libraw_cameraList();
  int libraw_cameraCount();
  void libraw_set_memerror_handler(libraw_data_t *, memory_callback cb, void *datap);
  void libraw_set_exifparser_handler(libraw_data_t *, exif_parser_callback cb, void *datap);
  void libraw_set_dataerror_handler(libraw_data_t *, data_callback func, void *datap);
  void libraw_set_progress_handler(libraw_data_t *, progress_callback cb, void *datap);
  const char *libraw_unpack_function_name(libraw_data_t *lr);
  int libraw_get_decoder_info(libraw_data_t *lr, libraw_decoder_info_t *d);
  int libraw_COLOR(libraw_data_t *, int row, int col);
  unsigned libraw_capabilities();
  int libraw_adjust_sizes_info_only(libraw_data_t *);
  int libraw_dcraw_ppm_tiff_writer(libraw_data_t *lr, const char *filename);
  int libraw_dcraw_thumb_writer(libraw_data_t *lr, const char *fname);
  int libraw_dcraw_process(libraw_data_t *lr);
  libraw_processed_image_t *libraw_dcraw_make_mem_image(libraw_data_t *lr, int *errc);
  libraw_processed_image_t *libraw_dcraw_make_mem_thumb(libraw_data_t *lr, int *errc);
  void libraw_dcraw_clear_mem(libraw_processed_image_t *);
  void libraw_set_demosaic(libraw_data_t *lr, int value);
  void libraw_set_output_color(libraw_data_t *lr, int value);
  void libraw_set_user_mul(libraw_data_t *lr, int index, float val);
  void libraw_set_output_bps(libraw_data_t *lr, int value);
  void libraw_set_gamma(libraw_data_t *lr, int index, float value);
  void libraw_set_no_auto_bright(libraw_data_t *lr, int value);
  void libraw_set_bright(libraw_data_t *lr, float value);
  void libraw_set_highlight(libraw_data_t *lr, int value);
  void libraw_set_fbdd_noiserd(libraw_data_t *lr, int value);
  int libraw_get_raw_height(libraw_data_t *lr);
  int libraw_get_raw_width(libraw_data_t *lr);
  int libraw_get_iheight(libraw_data_t *lr);
  int libraw_get_iwidth(libraw_data_t *lr);
  float libraw_get_cam_mul(libraw_data_t *lr, int index);
  float libraw_get_pre_mul(libraw_data_t *lr, int index);
  float libraw_get_rgb_cam(libraw_data_t *lr, int index1, int index2);
  int libraw_get_color_maximum(libraw_data_t *lr);
  libraw_iparams_t *libraw_get_iparams(libraw_data_t *lr);
  libraw_lensinfo_t *libraw_get_lensinfo(libraw_data_t *lr);
  libraw_imgother_t *libraw_get_imgother(libraw_data_t *lr);
