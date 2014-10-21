type readonly
type readwrite

val reaonly
val readwrite

type 'a t
type 'a t_init

val make_init_param: type a. string -> a t_access -> a t_init
val create: 'a t_init -> int -> t  (** Create with init and size params *)
val close: t -> unit
val get: t -> int -> bool
val set: t -> int -> bool

