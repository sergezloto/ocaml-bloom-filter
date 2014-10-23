# Bloom filter in Ocaml #

The aim is to have a generic bloom filter, usable with various problem domains.
A simple version, parametrized by hash function and bit storage
is in [bloomf.ml](bloomf.ml).
This is the one to use for now, as follows:

```
utop # let bf = create 1_000;;
val bf : t = {capacity = 1000; bits = <abstr>; nhash = 7}
utop # add bf "un";;
bool = false
utop # add bf "un";;
bool = true
utop # add bf "one";;
- : bool = false
```

-------------------------------------------------------------------------------

The rest is incomplete and subject to large changes..

TODOs, in no particular order:
- ~~provide reset~~. done
- make growable
- ~~add byte array storage~~. done
- ~~add mapped files storage~~. done
- add memcached like distributed memory storage
- make this a distributed service with distributed hash table
- provide save/load
- provide statistics
- set operations like union, intersection
- multilevel hashing to improve locality wrt problem domain

