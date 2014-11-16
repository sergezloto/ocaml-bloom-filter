module type HASH =
sig
  val seeded_hash: int -> 'a -> int
end

module type BITARRAY =
sig
  type t
  val create: nbits:int -> t
  val reset: t -> unit
  val set: t -> int -> bool
  val get: t-> int -> bool
  val length: t -> int
end

module type BLOOMF =
sig
  type 'a t
  type init_param

  exception Invalid_capacity
  exception Invalid_error_rate

  val init_cap_err: int -> float -> init_param
  val create: init_param -> 'a t
  val add: 'a t -> 'a -> bool
  val mem: 'a t -> 'a -> bool
  val reset: 'a t -> unit
  val get_capacity: 'a t -> int
  val get_error_rate: 'a t -> float
  val get_nbits: 'a t -> int
  val get_nhash: 'a t -> int
end

module Hash: HASH = 
struct
  let seeded_hash = Hashtbl.seeded_hash
end

module BitArray: BITARRAY = 
struct
  type t = char array  (* Note: byte array available from 4.02.0 *)

  let zero = '\x00'

  let create ~nbits =
    (* Adjust to next byte boundary. This way no bits wasted! *)
    let nbytes = (nbits + 7) / 8 in
    Array.make nbytes zero

  let reset b =
    Array.fill b 0 (Array.length b) zero

  let index i =
    (i asr 3, i land 7)  (* that is,  (i/8, i%8) *)

  let tbit byte bit =
    let byte = int_of_char byte in
    byte land (1 lsl bit) <> 0   (* test bit in byte *)

  let sbit byte bit = 
    let byte = int_of_char byte in
    char_of_int (byte lor (1 lsl bit))         (* set bit in byte *)

  let get b i =
    let (offset, bit) = index i in
    let byte = Array.get b offset in
    tbit byte bit

  let set (b:t) i =
    let (offset, bit) = index i in
    let byte = Array.get b offset in
    (* Check whether it was set *)
    if tbit byte bit then
      (* Was set, no need to update value *)
      true
    else
      let byte = sbit byte bit  in
      let _ = Array.set b offset byte in
      false

  let length b = Array.length b * 8
end

module Make(H: HASH)(B: BITARRAY) : BLOOMF =
struct
  type init_param = { capacity: int; error_rate: float; nbits: int; nhash: int;}

  type 'a t =  {
    param: init_param;
    bits: B.t; 
  }

  exception Invalid_capacity
  exception Invalid_error_rate

  let log2 = log 2.
  let sqlog2 = log2 *. log2

  let default_error_rate = 0.01

  (** Given desired capacity and error rates, return init parameter *)
  let init_cap_err capacity error_rate =
    if capacity <= 0 then raise Invalid_capacity;
    if error_rate <= 0. || error_rate > 1. then raise Invalid_error_rate;
    let fcap = float_of_int capacity in
    let nbits = 
      ~-. fcap *. (log error_rate) /. sqlog2 in
    (* Round hash functions up *)
    let nhash = int_of_float (ceil (log2 *. nbits /. fcap)) in
    (* Round nbits to upper byte boundary *)
    let nbits = ((int_of_float nbits) + 7) / 8 * 8 in (* or lsr 3 lsl 3 *)
    { capacity; error_rate; nbits; nhash;}

  let create  ({ capacity; error_rate; nbits; nhash;} as param) =
    let bits = B.create nbits in
    { param; bits;}

  let get_capacity bf = bf.param.capacity
  let get_error_rate bf = bf.param.error_rate
  let get_nbits bf = bf.param.nbits
  let get_nhash bf = bf.param.nhash

  let hash: 'a t -> int -> 'a -> int = fun bf seed elt ->
    let h = H.seeded_hash seed elt in
    h mod (B.length bf.bits) 
          
  let add: 'a t -> 'a -> bool = fun bf elt ->
    (* Hash and store, remember whether it had been stored *)
    let  collision = ref true in   (* assume collision to start with *)
    for h = 1 to bf.param.nhash do (* We seed with {1..nhash} *)
      let i = hash bf h elt in
      if not (B.set bf.bits i) then collision := false (* wasn't set prior so no collision *)
    done;
    !collision

  let mem: 'a t -> 'a -> bool = fun bf elt ->
    (* We seed with {1..nhash}, not with {0..nhash-1} for convenience *)
    let rec maux = function
      | 0 -> true
      | h -> let i = hash bf h elt in  (* hash to bit # *)
	if B.get bf.bits i then         (* inspect bit # *)
	  maux (h - 1)  (* true, keep going *)
	else
	  false  (* not member, no need to go further *)
    in
    maux bf.param.nhash

  let reset bf =
    B.reset bf.bits
end

(* Provide a default implementation in the current module *)
include Make(Hash)(BitArray)
