module S = Set.Make(struct type t=int let compare a b = if a < b then -1 else if a > b then 1 else 0  end)

let _ = Random.self_init ()
let bound = 1_000_000

let false_neg bf s =
  (* trials >> cap *)
  let trials = 100 * bf.Bloomf.capacity in
  let rec aux n fpos fneg =
    match n with
    | 0 -> 
       let trials = float_of_int trials in
       ((float_of_int fpos) /. trials, (float_of_int fneg) /. trials)
    | n ->  
       let elt = Random.int bound in
       if S.mem elt s then
	 (* a positive, check if false neg *)
	 match Bloomf.mem bf elt with
	 | false ->   (* Bloom filter says not member ! => false neg *)
	    aux n fpos (succ fneg)
	 | true ->
	    aux n fpos fneg
       else
	 match Bloomf.mem bf elt with
	 | false ->
	    aux (pred n) fpos fneg
	 | true -> (* false positive *)
	    aux (pred n) (succ fpos) fneg
  in
  aux trials 0 0
	 
let probtest capacity error_rate =
  let testelts = capacity * 2 in
  let bf = Bloomf.create ~error_rate ~capacity in
  (* Add elements, and check error rate *)
  let rec test s = function
    | n when n > testelts ->
       ()
    | n ->
       let elt = Random.int bound in
       if S.mem elt s then
	 test s n   (* elt was in set, skip *)
       else
	 let s = S.add elt s
	 and _ = Bloomf.add bf elt in
	 let (fpos, fneg) = false_neg bf s in
	 Printf.printf "%d, %02.5f, %02.5f\n" n fpos fneg;
	 test s (succ n)
  in
  Printf.printf "## Test bloom filter (%s) with nominal capacity %d and error_rate %0.3f\n" __FILE__ capacity error_rate;
  Printf.printf "n, fpos, fneg\n";
  test S.empty 0

let _ = 
  probtest 1_000 0.05
