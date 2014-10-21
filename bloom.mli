(** Bloom filter

  [Bloom] implements a vanilla Bloom filter, a test for membership 
  of an  element in a set with advantageous space requirements, at the cost
  of a given probability of returning a false positive.
  In particular, the element itself need not be stored.
  Once created, the bloom filter capacity does not change.
  The element type must support hashing.
  Consistent with definition, a Bloom filter may indicate a false positive.
  It is up to the user of [Bloom] to decide whether to check whether a positive is real.
  
  @see <https://en.wikipedia.org/wiki/Bloom_filter> Bloom Filter *)

(** Bit stores for the bloom filter must be implemented by modules that conform
  to this signature *)
module type BIT_STORE = sig
    type t
    type t_init  (** Initialisation parameters for the bit store *)
    val create: t_init -> nbits:int -> t
    val close: t -> unit
    val get: int -> bool
    val set: int -> bool
  end


type ('a, 's) t
(** Type of a Bloom filter for element type ['a] with storage type 'b *)

val default_error_rate: float
(** Default is 1% = [0.01] *)

exception Invalid_capacity
exception Invalid_error_rate

val space_required: capacity:int -> error_rate:float  -> int
(** @return the space requirements of a Bloom filter with the given parameters in bits *)

val create: capacity:int -> ?error_rate:float 
	    -> ?seeded_hash:(int -> 'a -> int) 
	    -> ?bit_store: (module BIT_STORE)
	    -> ?bit_store_init: 's
	    -> unit ->  ('a, 's) t
(** [create capacity error_rate ()] returns a Bloom filter with specified characteristics.
  @param capacity is the number of elements expected to be entered stored in the filter. 
                  while complying to the error_rate.
  @param error_rate the target rate of false positives. Between [0] and [1], default is [0.01f]
  @param seeded_hash the hash functions to use. Default is [Hashtbl.seeded_hash]
  @param bit_store the bit storage engine to use for the filter. Default is [Storage_mm]
  @param bit_store_init initialization for the bit store instance
  @raise Invalid_capacity
  @raise Invalid_error_rate  *)

val add: ('a, 's) t -> elt:'a -> bool
(** [add bf elt] adds the element [elt] to the filter [bf] 
  @return [false] if [elt] was already marked as a member *)

val mem: ('a, 's) t -> elt:'a -> bool
(** If [mem bf elt] returns [false], then [elt] does not belong to the set. If [true],
  it belongs with a probability of [1 - err_rate] (when the filter is at nominal capacity). *)

val length: ('a, 's) t -> int
(** The number of elements added in the set *)
