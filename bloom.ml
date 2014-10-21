(* TODO: MAKE STORAGE GENERIC.
- make bit storage engine generic
- provide clear, reset
- make growable
- add byte array storage
+ add mapped files storage
- add memcached like distributed memory storage
- make this a distributed service with distributed hash table
- provide save/load, persist params including statistics
- multilevel hashing to improve locality wrt problem domain
*)

module type BIT_STORE = sig
    type t
    type t_init
    val create: t_init -> int -> t  (** Create with init and size params *)
    val close: t -> unit
    val get: t -> int -> bool
    val set: t -> int -> bool
  end


type ('a, 's) t = {
  capacity: int;
  error_rate: float;
  nbits: int;
  nhash: int;
  seeded_hash: int -> 'a -> int;
  bit_store: (module BIT_STORE);
  bit_store_instance: 's;
  mutable count: int;
}

exception Invalid_capacity
exception Invalid_error_rate

let default_error_rate = 0.001
let default_seeded_hash = Hashtbl.seeded_hash
let default_bit_store = (module Storage_mm: BIT_STORE)

(* The number of hash functions and space required for capacity c and error_rate fp 
  is given by 
  nbits = - c log fp / (log2 ^ 2)
  nhash = log2 . nbits/c
*)
  
let log2 = log 2.
let sqlog2 = log2 *. log2

let space_required ~capacity ~error_rate = 
  if capacity < 0 then raise Invalid_capacity;
  if error_rate < 0. || error_rate > 1. then raise Invalid_error_rate;
  let capacity = float_of_int capacity in
  let nbits = 
    ~-. capacity *. (log error_rate) /. sqlog2 in
  (* Round hash functions up *)
  let nhash = int_of_float (ceil (log2 *. nbits /. capacity)) in
  (* Round nbits to upper byte boundary *)
  let nbits = ((int_of_float nbits) + 7) / 8 * 8;  (* or lsr 3 lsl 3 *)
  in (nbits, nhash)
			       
  
let hash bf seed elt =
  let h = bf.seeded_hash seed elt in
  h mod bf.nbits

let create ~capacity ?(error_rate = default_error_rate) 
	   ?(seeded_hash = default_seeded_hash)
	   ?(bit_store = (module Storage_mm: BIT_STORE)) 
	   ?(bit_store_init) () =
  let (nbits, hhash) = space_required capacity error_rate in
  (* Setup our bit store *)
  let bit_store = 
    let module S = (val bit_store: BIT_STORE) in
    bit_store_instance = S.create bit_store_init nbits in
  {
    capacity;
    error_rate;
    nbits;
    nhash;
    seeded_hash;
    bit_store;
    bit_store_instance;
    count = 0;
  }

let add bf elt =
  let module S = (val bf.bit_store: BIT_STORE) in
  let bs = bf.bit_store_instance
  (* Hash and store, remember whether it had been stored *)
  and  collision = ref true in   (* assume collision to start with *)
  for h = 0 to bf.nhash do 
      let i = hash h elt in
      if not (S.add bs i) then collision := false
  done;
  if !collision then true else bf.count <- succ bf.count; false

let mem bf elt =
  let module S = (val bf.bit_store: BIT_STORE) in
  let bs = bf.bit_store_instance in
  let rec maux = function
    | 0 -> true
    | h -> let i = hash h elt in
	   if S.get bs i then
	     maux (h - 1)
	   else
	     false  (* not member, no need to go further *)
  in
  maux bf.nhash
