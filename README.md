= Bloom filter in Ocaml

The aim is to have a generic bloom filter, usable with various problem domains.
Very incomplete for now.

Laundry list of features:
- make bit storage engine generic
- provide clear, reset
- make growable
- add byte array storage
- add mapped files storage. DONE
- add memcached like distributed memory storage
- make this a distributed service with distributed hash table
- provide save/load, persist params including statistics
- multilevel hashing to improve locality wrt problem domain

