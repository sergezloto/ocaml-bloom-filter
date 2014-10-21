(** Mapped file bit storage for Bloom filter.
  This allows the storage to be greater than physical memory, at the cost 
  of page faults.
  The backing file starts off hollow and zeroed.
  Also, the storage is made persistent this way by choosing the same backing file
  with the same size in bits. This makes it possible for multiple applications
  to use the same mapped file and share the information. In this case there
  should be at most a single writer because of lack of synchronization.

  Note: to use only on 64 bit systems when the number of bits is greater than 2^33.

  @date 2014-10-20
  @author Serge Zloto
 *)

open Bigarray

(** Storage type for our bits *)
type storage = (int, int8_unsigned_elt, c_layout) Array1.t

type readonly
type readwrite
 
(** GADT for ensuring we perform safe operations *)
type _ t_access =
  | Readonly: readonly  t_access
  | Readwrite: readwrite t_access

let readonly = Readonly
let readwrite = Readwrite 


(** Info content for storage, parametrized by access *)
type 'a t = 'a t_access  * Unix.file_descr * storage

(** Init parameters *)
type 'a t_init = string * 'a t_access 

(** Create initialization *)
let make_init_param: type a. string -> a t_access -> a t_init =
	      fun s a -> (s, a)

(** [create init_param size] creates an array backed by a write-back mapped file.
    The file is created with the specified size and zeroed 
    if non existent.
  @param init_param filename for the mapped file.
  @param size requested storage size in bits
  @raise Unix.Unix_error if file cannot be opened or created *)
let create: type a. a t_init -> int -> a t =
                fun (fn, a) nbits ->
                let fd = 
                  let open Unix in
                  let mode = 
                    match a with
                    | Readonly -> [O_RDONLY]
                    | Readwrite -> [O_CREAT; O_RDWR]
                  and perm = 0o640 in  (* access permission rw-r----- *)
                  openfile fn mode perm
                and shared = true (* we want to allow a writer, many readers *)
                and nbytes = nbits / 8 in
                let ba = Array1.map_file fd int8_unsigned c_layout shared nbytes in 
                (* If just created, file is zeroed *)
                (a, fd, ba)

(** Closes the storage and releases resources *)
let close (_, fd, _) =
  let open Unix in
  try close fd with Unix_error(EBADF,_,_) -> ()

(** Computes the byte and bit at which the requested index resides *)
let index i =
  (i asr 3, i land 7)  (* that is,  (i/8, i%8) *)

(** [get s i] returns the bit at index [i] in storage.
  Indexes begin at 0.
  @return true if position is set 
  @raise Invalid_argument if [i] is out of bounds*)
let get: _ t -> int -> bool =
  fun (_, _, ba) i ->
  let (offset, bit) = index i in
  let byte = Array1.get ba offset in
  byte land (1 lsl bit) <> 0

(** [set s i v] sets the bit at index [i] in storage 
  @return true if bit was already set
  @raise Invalid_argument if [i] is out of bounds*)
let set: _ t -> int -> bool = 
  fun (_, _, ba) i ->
  let (offset, bit) = index i in
  let byte = Array1.get ba offset in
  (* Check whether it was set *)
  if byte land (1 lsl bit) <> 0 then
    (* Was set, no need to update value *)
    true
  else
    let byte = byte lor (1 lsl bit) in
    let _ = Array1.set ba offset byte in
    false

let _ =
  let nbits = 100 * 1_000_000_000 in
  let ii = make_init_param  "/tmp/tt.storage" readwrite in
  let s = create ii nbits in
  set s 1;
  set s (nbits - 1);
  ignore (get s 1234);
  close s
