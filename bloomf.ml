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

module Make(H: HASH)(B: BITARRAY) =
  struct
    type t = { 
      capacity:int; 
      bits: B.t; 
      nhash: int;
    }

    exception Invalid_capacity
    exception Invalid_error_rate

    let log2 = log 2.
    let sqlog2 = log2 *. log2

    let default_error_rate = 0.01

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
	   
    let create ?(error_rate = default_error_rate) ~capacity =
      let (nbits, nhash) = space_required capacity error_rate in
      let bits = B.create nbits in
      { capacity; bits; nhash; }

    let hash bf seed elt =
      let h = H.seeded_hash seed elt in
      h mod (B.length bf.bits) 

    let add bf elt =
      (* Hash and store, remember whether it had been stored *)
      let  collision = ref true in   (* assume collision to start with *)
      for h = 0 to bf.nhash do 
	let i = hash bf h elt in
	if not (B.set bf.bits i) then collision := false (* wasn't set prior so no collision *)
      done;
      !collision

    let mem bf elt =
      (* We seed with {1..nhash}, not with {0..nhash-1} for convenience *)
      let rec maux = function
	| 0 -> true
	| h -> let i = hash bf h elt in  (* hash to bit # *)
	       if B.get bf.bits i then         (* inspect bit # *)
		 maux (h - 1)  (* true, keep going *)
	       else
		 false  (* not member, no need to go further *)
      in
      maux bf.nhash
  end

(* Provide a default implementation in the current module *)
include Make(Hash)(BitArray)
