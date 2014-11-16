(** A simple Bloom filter, as a functor parametrized by hash function 
    and bit storage engine.
    A default implementation is provided.
*)

module type HASH = sig val seeded_hash : int -> 'a -> int end
module type BITARRAY =
sig
  type t
  val create : nbits:int -> t
  val reset : t -> unit
  val set : t -> int -> bool
  val get : t -> int -> bool
  val length : t -> int
end

(** A Bloom filter provides for creation, membership and addition only *)
module type BLOOMF =
sig
  (** The type of the Bloom filter *)
  type 'a t
  (** Created with this type *)
  type init_param
  exception Invalid_capacity
  exception Invalid_error_rate
  (** Sets up init parameters with given capacity and target error rate *)
  val init_cap_err : int -> float -> init_param
  (** Instantiates the filter *)
  val create : init_param -> 'a t
  (** Adds an element to the set.
      @return true if the element was deemed a member of the set
  *)
  val add : 'a t -> 'a -> bool
  (** @return true if the element is deemed a member of the set *)
  val mem : 'a t -> 'a -> bool
  (** Returns the set to an empty state *)
  val reset : 'a t -> unit
  val get_capacity : 'a t -> int
  val get_error_rate : 'a t -> float
  val get_nbits : 'a t -> int
  val get_nhash : 'a t -> int
end

(** Default Hash module *)
module Hash : HASH

(** Default bit storage, memory based *)
module BitArray : BITARRAY

(** Bloom filter functor *)
module Make : functor (H : HASH) -> functor (B : BITARRAY) -> BLOOMF

(* Bring the interface into the current module *)
include BLOOMF
  
