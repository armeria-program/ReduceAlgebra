% Checks on basic arithmetic..."

% This rather crude set of tests was used for initial and basic
% functionality-testing of arithmetic when CSL was adapted for use
% on 64-bit architectures. It may still be useful as a minimal part of
% a set of regression tests...

(de tests (a b r)
  (prog (w)
     (setq w (list (plus a b) (plus b a)))
     (setq w (list!* (difference a b) (difference b a) w))
     (setq w (list!* (times a b) (times b a) w))
     (setq w (list!* (quotient a b) (quotient b a) w))
     (setq w (list!* (remainder a b) (remainder b a) w))
     (setq w (list!* (greaterp a b) (greaterp b a) w))
     (setq w (list!* (lessp a b) (lessp b a) w))
     (setq w (list!* (equal a b) (equal b a) w))
%    (terpri) (print (list 'tests a b (list 'quote w)))
     (cond ((not (equal r w))
            (terpri)
            (printc "*** ERROR ***")
            (princ "a = ") (print a)
            (princ "b = ") (print b)
            (showall r w)
            (error 0 "messed up")))
     (return nil)))

(de showall (r w)
  (prog (z)
    (princ "op")
    (ttab 5) (princ "correct")
    (ttab 40) (printc "computed")
    (setq z '(!= != !< !< !> !> !% !% !/ !/ !* !* !- !- !+ !+))
top (cond ((or (null r) (null w) (null z)) (return nil)))
    (cond 
       ((equal (car r) (car w)) 
         (princ "  ")) 
       (t (princ "? ")))
    (princ (car z)) (ttab 5)
    (prin (car r)) (ttab 40) (print (car w))
    (setq r (cdr r)) (setq w (cdr w)) (setq z (cdr z))
    (go top)))

(tests 1 1 (quote (t t nil nil nil nil 0 0 1 1 1 1 0 0 2 2)))

(tests 1 2 (quote (nil nil t nil nil t 1 0 0 2 2 2 -1 1 3 3)))

(tests 1 10000 (quote (nil nil t nil nil t 1 0 0 10000 10000 10000
-9999 9999 10001 10001)))

(tests 1 1000000000 (quote (nil nil t nil nil t 1 0 0 1000000000
1000000000 1000000000 -999999999 999999999 1000000001 1000000001))
)

(tests 1 100000000000000000000 (quote (nil nil t nil nil t 1 0 0
100000000000000000000 100000000000000000000 100000000000000000000
-99999999999999999999 99999999999999999999 100000000000000000001
100000000000000000001)))

(tests 1 100000000000000000000000000000000 (quote (nil nil t nil
nil t 1 0 0 100000000000000000000000000000000
100000000000000000000000000000000
100000000000000000000000000000000
-99999999999999999999999999999999 99999999999999999999999999999999
100000000000000000000000000000001
100000000000000000000000000000001)))

(tests 3 1 (quote (nil nil nil t t nil 0 1 3 0 3 3 2 -2 4 4)))

(tests 3 2 (quote (nil nil nil t t nil 1 2 1 0 6 6 1 -1 5 5)))

(tests 3 10000 (quote (nil nil t nil nil t 3 1 0 3333 30000 30000
-9997 9997 10003 10003)))

(tests 3 1000000000 (quote (nil nil t nil nil t 3 1 0 333333333
3000000000 3000000000 -999999997 999999997 1000000003 1000000003))
)

(tests 3 100000000000000000000 (quote (nil nil t nil nil t 3 1 0
33333333333333333333 300000000000000000000 300000000000000000000
-99999999999999999997 99999999999999999997 100000000000000000003
100000000000000000003)))

(tests 3 100000000000000000000000000000000 (quote (nil nil t nil
nil t 3 1 0 33333333333333333333333333333333
300000000000000000000000000000000
300000000000000000000000000000000
-99999999999999999999999999999997 99999999999999999999999999999997
100000000000000000000000000000003
100000000000000000000000000000003)))

(tests 7777 1 (quote (nil nil nil t t nil 0 1 7777 0 7777 7777 7776
-7776 7778 7778)))

(tests 7777 2 (quote (nil nil nil t t nil 1 2 3888 0 15554 15554
7775 -7775 7779 7779)))

(tests 7777 10000 (quote (nil nil t nil nil t 7777 2223 0 1
77770000 77770000 -2223 2223 17777 17777)))

(tests 7777 1000000000 (quote (nil nil t nil nil t 7777 2232 0
128584 7777000000000 7777000000000 -999992223 999992223 1000007777
1000007777)))

(tests 7777 100000000000000000000 (quote (nil nil t nil nil t 7777
3334 0 12858428700012858 777700000000000000000000
777700000000000000000000 -99999999999999992223
99999999999999992223 100000000000000007777 100000000000000007777))
)

(tests 7777 100000000000000000000000000000000 (quote (nil nil t nil
nil t 7777 3334 0 12858428700012858428700012858
777700000000000000000000000000000000
777700000000000000000000000000000000
-99999999999999999999999999992223 99999999999999999999999999992223
100000000000000000000000000007777
100000000000000000000000000007777)))

(tests 3141592653882 1 (quote (nil nil nil t t nil 0 1
3141592653882 0 3141592653882 3141592653882 3141592653881
-3141592653881 3141592653883 3141592653883)))

(tests 3141592653882 2 (quote (nil nil nil t t nil 0 2
1570796326941 0 6283185307764 6283185307764 3141592653880
-3141592653880 3141592653884 3141592653884)))

(tests 3141592653882 10000 (quote (nil nil nil t t nil 3882 10000
314159265 0 31415926538820000 31415926538820000 3141592643882
-3141592643882 3141592663882 3141592663882)))

(tests 3141592653882 1000000000 (quote (nil nil nil t t nil
592653882 1000000000 3141 0 3141592653882000000000
3141592653882000000000 3140592653882 -3140592653882 3142592653882
3142592653882)))

(tests 3141592653882 100000000000000000000 (quote (nil nil t nil
nil t 3141592653882 1933393904584 0 31830988
314159265388200000000000000000000
314159265388200000000000000000000 -99999996858407346118
99999996858407346118 100000003141592653882 100000003141592653882))
)

(tests 3141592653882 100000000000000000000000000000000 (quote (nil
nil t nil nil t 3141592653882 1024789465762 0 31830988615418393659
314159265388200000000000000000000000000000000
314159265388200000000000000000000000000000000
-99999999999999999996858407346118 99999999999999999996858407346118
100000000000000000003141592653882
100000000000000000003141592653882)))

(tests 7788882333333333300000000000000331 1 (quote (nil nil nil t t
nil 0 1 7788882333333333300000000000000331 0
7788882333333333300000000000000331
7788882333333333300000000000000331
7788882333333333300000000000000330
-7788882333333333300000000000000330
7788882333333333300000000000000332
7788882333333333300000000000000332)))

(tests 7788882333333333300000000000000331 2 (quote (nil nil nil t t
nil 1 2 3894441166666666650000000000000165 0
15577764666666666600000000000000662
15577764666666666600000000000000662
7788882333333333300000000000000329
-7788882333333333300000000000000329
7788882333333333300000000000000333
7788882333333333300000000000000333)))

(tests 7788882333333333300000000000000331 10000 (quote (nil nil nil
t t nil 331 10000 778888233333333330000000000000 0
77888823333333333000000000000003310000
77888823333333333000000000000003310000
7788882333333333299999999999990331
-7788882333333333299999999999990331
7788882333333333300000000000010331
7788882333333333300000000000010331)))

(tests 7788882333333333300000000000000331 1000000000 (quote (nil
nil nil t t nil 331 1000000000 7788882333333333300000000 0
7788882333333333300000000000000331000000000
7788882333333333300000000000000331000000000
7788882333333333299999999000000331
-7788882333333333299999999000000331
7788882333333333300000001000000331
7788882333333333300000001000000331)))

(tests 7788882333333333300000000000000331 100000000000000000000 (
quote (nil nil nil t t nil 33300000000000000331
100000000000000000000 77888823333333 0
778888233333333330000000000000033100000000000000000000
778888233333333330000000000000033100000000000000000000
7788882333333233300000000000000331
-7788882333333233300000000000000331
7788882333333433300000000000000331
7788882333333433300000000000000331)))

(tests 7788882333333333300000000000000331
100000000000000000000000000000000 (quote (nil nil nil t t nil
88882333333333300000000000000331 100000000000000000000000000000000
77 0
778888233333333330000000000000033100000000000000000000000000000000
778888233333333330000000000000033100000000000000000000000000000000
7688882333333333300000000000000331
-7688882333333333300000000000000331
7888882333333333300000000000000331
7888882333333333300000000000000331)))

(tests -1 1 (quote (nil nil t nil nil t 0 0 -1 -1 -1 -1 -2 2 0 0))
)

(tests -1 2 (quote (nil nil t nil nil t -1 0 0 -2 -2 -2 -3 3 1 1))
)

(tests -1 10000 (quote (nil nil t nil nil t -1 0 0 -10000 -10000
-10000 -10001 10001 9999 9999)))

(tests -1 1000000000 (quote (nil nil t nil nil t -1 0 0
-1000000000 -1000000000 -1000000000 -1000000001 1000000001
999999999 999999999)))

(tests -1 100000000000000000000 (quote (nil nil t nil nil t -1 0 0
-100000000000000000000 -100000000000000000000
-100000000000000000000 -100000000000000000001
100000000000000000001 99999999999999999999 99999999999999999999)))

(tests -1 100000000000000000000000000000000 (quote (nil nil t nil
nil t -1 0 0 -100000000000000000000000000000000
-100000000000000000000000000000000
-100000000000000000000000000000000
-100000000000000000000000000000001
100000000000000000000000000000001 99999999999999999999999999999999
99999999999999999999999999999999)))

(tests -3 1 (quote (nil nil t nil nil t 0 1 -3 0 -3 -3 -4 4 -2 -2)
))

(tests -3 2 (quote (nil nil t nil nil t -1 2 -1 0 -6 -6 -5 5 -1 -1
)))

(tests -3 10000 (quote (nil nil t nil nil t -3 1 0 -3333 -30000
-30000 -10003 10003 9997 9997)))

(tests -3 1000000000 (quote (nil nil t nil nil t -3 1 0 -333333333
-3000000000 -3000000000 -1000000003 1000000003 999999997 999999997
)))

(tests -3 100000000000000000000 (quote (nil nil t nil nil t -3 1 0
-33333333333333333333 -300000000000000000000
-300000000000000000000 -100000000000000000003
100000000000000000003 99999999999999999997 99999999999999999997)))

(tests -3 100000000000000000000000000000000 (quote (nil nil t nil
nil t -3 1 0 -33333333333333333333333333333333
-300000000000000000000000000000000
-300000000000000000000000000000000
-100000000000000000000000000000003
100000000000000000000000000000003 99999999999999999999999999999997
99999999999999999999999999999997)))

(tests -7777 1 (quote (nil nil t nil nil t 0 1 -7777 0 -7777 -7777
-7778 7778 -7776 -7776)))

(tests -7777 2 (quote (nil nil t nil nil t -1 2 -3888 0 -15554
-15554 -7779 7779 -7775 -7775)))

(tests -7777 10000 (quote (nil nil t nil nil t -7777 2223 0 -1
-77770000 -77770000 -17777 17777 2223 2223)))

(tests -7777 1000000000 (quote (nil nil t nil nil t -7777 2232 0
-128584 -7777000000000 -7777000000000 -1000007777 1000007777
999992223 999992223)))

(tests -7777 100000000000000000000 (quote (nil nil t nil nil t
-7777 3334 0 -12858428700012858 -777700000000000000000000
-777700000000000000000000 -100000000000000007777
100000000000000007777 99999999999999992223 99999999999999992223)))

(tests -7777 100000000000000000000000000000000 (quote (nil nil t
nil nil t -7777 3334 0 -12858428700012858428700012858
-777700000000000000000000000000000000
-777700000000000000000000000000000000
-100000000000000000000000000007777
100000000000000000000000000007777 99999999999999999999999999992223
99999999999999999999999999992223)))

(tests -3141592653882 1 (quote (nil nil t nil nil t 0 1
-3141592653882 0 -3141592653882 -3141592653882 -3141592653883
3141592653883 -3141592653881 -3141592653881)))

(tests -3141592653882 2 (quote (nil nil t nil nil t 0 2
-1570796326941 0 -6283185307764 -6283185307764 -3141592653884
3141592653884 -3141592653880 -3141592653880)))

(tests -3141592653882 10000 (quote (nil nil t nil nil t -3882 10000
-314159265 0 -31415926538820000 -31415926538820000 -3141592663882
3141592663882 -3141592643882 -3141592643882)))

(tests -3141592653882 1000000000 (quote (nil nil t nil nil t
-592653882 1000000000 -3141 0 -3141592653882000000000
-3141592653882000000000 -3142592653882 3142592653882
-3140592653882 -3140592653882)))

(tests -3141592653882 100000000000000000000 (quote (nil nil t nil
nil t -3141592653882 1933393904584 0 -31830988
-314159265388200000000000000000000
-314159265388200000000000000000000 -100000003141592653882
100000003141592653882 99999996858407346118 99999996858407346118)))

(tests -3141592653882 100000000000000000000000000000000 (quote (
nil nil t nil nil t -3141592653882 1024789465762 0
-31830988615418393659
-314159265388200000000000000000000000000000000
-314159265388200000000000000000000000000000000
-100000000000000000003141592653882
100000000000000000003141592653882 99999999999999999996858407346118
99999999999999999996858407346118)))

(tests -7788882333333333300000000000000331 1 (quote (nil nil t nil
nil t 0 1 -7788882333333333300000000000000331 0
-7788882333333333300000000000000331
-7788882333333333300000000000000331
-7788882333333333300000000000000332
7788882333333333300000000000000332
-7788882333333333300000000000000330
-7788882333333333300000000000000330)))

(tests -7788882333333333300000000000000331 2 (quote (nil nil t nil
nil t -1 2 -3894441166666666650000000000000165 0
-15577764666666666600000000000000662
-15577764666666666600000000000000662
-7788882333333333300000000000000333
7788882333333333300000000000000333
-7788882333333333300000000000000329
-7788882333333333300000000000000329)))

(tests -7788882333333333300000000000000331 10000 (quote (nil nil t
nil nil t -331 10000 -778888233333333330000000000000 0
-77888823333333333000000000000003310000
-77888823333333333000000000000003310000
-7788882333333333300000000000010331
7788882333333333300000000000010331
-7788882333333333299999999999990331
-7788882333333333299999999999990331)))

(tests -7788882333333333300000000000000331 1000000000 (quote (nil
nil t nil nil t -331 1000000000 -7788882333333333300000000 0
-7788882333333333300000000000000331000000000
-7788882333333333300000000000000331000000000
-7788882333333333300000001000000331
7788882333333333300000001000000331
-7788882333333333299999999000000331
-7788882333333333299999999000000331)))

(tests -7788882333333333300000000000000331 100000000000000000000 (
quote (nil nil t nil nil t -33300000000000000331
100000000000000000000 -77888823333333 0
-778888233333333330000000000000033100000000000000000000
-778888233333333330000000000000033100000000000000000000
-7788882333333433300000000000000331
7788882333333433300000000000000331
-7788882333333233300000000000000331
-7788882333333233300000000000000331)))

(tests -7788882333333333300000000000000331
100000000000000000000000000000000 (quote (nil nil t nil nil t
-88882333333333300000000000000331
100000000000000000000000000000000 -77 0
-778888233333333330000000000000033100000000000000000000000000000000
-778888233333333330000000000000033100000000000000000000000000000000
-7888882333333333300000000000000331
7888882333333333300000000000000331
-7688882333333333300000000000000331
-7688882333333333300000000000000331)))

(stop 0)
