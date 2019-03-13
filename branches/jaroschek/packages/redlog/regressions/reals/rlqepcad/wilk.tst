% Testing rlcad

% Wilkinson's polynomial. Tests how fast root isolation is.

rlset reals;

load_package qepcad;

rlrndseed 19;

wilk := ex(x,8388608*x**20 + 1761607681*x**19 + 172931153920*x**18 +
10543221964800*x**17 + 447347234439168*x**16 +
14028108264898560*x**15 + 336985244869591040*x**14 +
6342720331186176000*x**13 + 94877480085669019648*x**12 +
1137370949952460554240 *x**11 + 10968398649699241820160*x**10 +
85079777790228273561600*x**9 + 528740774622641958944768 *x**8 +
2611655889692786813829120*x**7 + 10122095419974470210682880*x**6 +
30198816984091441338777600 *x**5 + 67426052557934862488567808*x**4 +
107969196810523545855590400*x**3 + 115794329499468438700032000 *x**2 +
73425049924762651852800000*x + 20408661249006627717120000 = 0
and -20<=x<=-10)$

rlqepcad wilk;

end;
