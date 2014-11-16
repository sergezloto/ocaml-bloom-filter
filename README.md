# Bloom filter in Ocaml #

The aim is to have a generic bloom filter, usable with various problem domains.
A simple version, parametrized by hash function and bit storage
is in [bloomf.ml](bloomf.ml).
Use as follows:
```
# let init_params = init_cap_err 1_000 0.05;; (* target error rate is 5% *)
val init_params : init_param = <abstr>
# let bf = create init_params;;
val bf : '_a t = <abstr>
# add bf "un";;
- : bool = false
# add bf "one";;
- : bool = false
# add bf "un";;
- : bool = true
# get_nbits bf;;
- : int = 6240
# mem bf "one";;
- : bool = true
# mem bf "eins";;
- : bool = false
```

The filter performance degrades rapidly when its nominal capacity is exceeded:
<img src="errors.png">

-------------------------------------------------------------------------------

Possible enhancements and TODOs, in no particular order:
- [ ] make init parameters more flexible
- [x] provide reset
- [ ] make growable
- [x] add byte array storage
- [ ] add mapped files storage
- [ ] add memcached like distributed memory storage
- [ ] make this a distributed service with distributed hash table
- [ ] provide save/load
- [ ] provide statistics
- [ ] set operations like union, intersection
- [ ] multilevel hashing to improve locality wrt problem domain
