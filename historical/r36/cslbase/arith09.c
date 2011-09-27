
/*  arith09.c                         Copyright (C) 1989-1996 Codemist Ltd */

/*
 * Arithmetic functions.
 *    GCD and some boolean operations
 *
 * Version 1.2   October 1992.
 */

/* Signature: 365c3dca 07-Mar-2000 */

#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#include "machine.h"
#include "tags.h"
#include "cslerror.h"
#include "externs.h"
#include "arith.h"
#ifdef TIMEOUT
#include "timeout.h"
#endif

static Lisp_Object absb(Lisp_Object a)
/*
 * take absolute value of a bignum
 */
{
    int32 len = bignum_length(a) >> 2;
    if ((int32)bignum_digits(a)[len-2] < 0) return negateb(a);
    else return a;
}

/*
 * The next two functions help with bignum GCDs
 */
 
static void next_gcd_step(unsigned32 a0, unsigned32 a1,
                          unsigned32 b0, unsigned32 b1,
                          int32 *axp, int32 *ayp, int32 *bxp, int32*byp)
/*
 * This function takes the two leading digits (a0,a1) and (b0,b1) of
 * a pair of numbers A and B and performs an extended GCD process to
 * find values ax, bx, ay and by with a view to letting
 *   A' = ax*A + ay*B
 *   B' = bx*A + by*B
 * and gcd(A', B') will be the same as gcd(A, B), but A' and B' will
 * be smaller than A and B by a factor of (up to, about) 2^30.  On entry
 * A must be at least as big as B and B must be nonzero. If A/B is
 * bigger than about 0x40000000 the code will return early without doing
 * much - this must be detected and handled by the caller.  The case where
 * no progress has been made will be signalled because the values ax, ay,
 * bx and by will be returned as ((1, 0), (0, 1)).  Note that through the
 * body of this code axy and bxy hold ax+ay and bx+by
 */
{
    int32 ax = 1, axy = 1,
          bx = 0, bxy = 1;
    unsigned32 q;
    int n = 0;
/*
 * I will keep A and B as double-precision values with a view to getting
 * the most progress out of this that I can.  Also I round B up, so that
 * the quotient (A/B) is guaranteed to be an under-estimate for the true
 * result.  Note that A was rounded down just by the process of keeping
 * only the two leading digits.
 */
    b1++;
    if ((int32)b1 < 0)
    {   b0++;
        b1 = 0;  /* carry if necessary */
    }
/*
 * If b0 overflowed here then both A and B must have started off as
 * 0x7fffffff:0x7fffffff (since B was like that to overflow when incremented,
 * and A>=B).  I return as if this code was invalid, and the fall-back
 * case will do one step and tidy up a bit. A jolly uncommon case!
 */
    if ((int)b0 >= 0)
    {   for (;;)
        {   unsigned32 c0, c1;
/*
 * If A/B would overflow I break.  This includes the special case where B
 * has reduced to zero.  I compute q = (a0,a1)/(b0,b1)
 */
            if (b0 == 0)
            {   unsigned32 qt;
                if (a0 >= b1) break; /* Overflow exit */
                Ddivide(a1, qt, a0, a1, b1);
                a0 = 0;              /* Leave the remainder in A */
                q = qt;              /* Accurate quotient here */
            }
            else
/*
 * I expect that the quotient here will be quite small, so I compute it in
 * a way optimised for such cases.  This is just a simple shift-and-subtract
 * bit of division code, but for small quotients the number of loops executed
 * will be small.  This naturally leaves the remainder in A.
 */
            {   unsigned32 qt = 1;
                q = 0;
/*
 * This code uses B (it shifts it left a few bits to start with) but at the
 * end B has been put back in its original state.
 */
                while (b0 < a0)     /* Shift B left until >= A */
                {   b0 = b0 << 1;
                    b1 = b1 << 1;
                    if ((int32)b1 < 0)
                    {   b0++;
                        b1 &= 0x7fffffff;
                    }
                    qt = qt << 1;   /* qt marks a bit position */
                }
                for (;;)            /* Shift/subtract loop to get quotient */
                {   if (b0 < a0 ||
                        (b0 == a0 && b1 <= a1))
                    {   q |= qt;
                        a0 -= b0;
                        a1 -= b1;
                        if ((int32)a1 < 0)
                        {   a0--;
                            a1 &= 0x7fffffff;
                        }
                    }
                    qt = qt >> 1;
                    if (qt == 0) break;
                    b1 = b1 >> 1;
                    if ((b0 & 1) != 0) b1 |= 0x40000000;
                    b0 = b0 >> 1;
                }
            }
/*
 * Now A hold the next remainder onwards, so flip A and B
 */
            c0 = a0; c1 = a1; a0 = b0; a1 = b1; b0 = c0; b1 = c1;
/*
 * If either of the next re-calculations of bx, bxy overflow then I ought
 * to exit before updating ax, bx, axy and bxy. Things are arranged so that
 * all values remain positive at this stage.
 */
            {   unsigned32 cx, cxy;
                Dmultiply(cx, cxy, bxy, q, axy);
                if (cx != 0) break;
/*
 * cxy will be >= cx, so if cxy did not overflow then cx can not. Thus it
 * is safe to use regular (not double-length) multiplication here.
 */
                cx = bx*q + ax;
                axy = bxy; bxy = cxy;
                ax = bx; bx = cx;
                n++;
            }
/*
 * I update A and B in such a way that they alternate between the
 * sequences for under- and over-estimates of the true ratio.  This is done
 * so that the partial quotients I compute always tend to be underestimates.
 */
            a1 = a1 - axy;
            if ((int32)a1 < 0)
            {   a1 &= 0x7fffffff;
                a0--;
            }
            b1 = b1 + bxy;
            if ((int32)b1 < 0)
            {   b1 &= 0x7fffffff;
                b0++;
            }
            if (b0 > a0 ||
                (b0 == a0 && b1 >= a1)) break;
        }
    }    /* This is the end of the block testing the initial quotient */
    {   int32 ay = axy - ax,
              by = bxy - bx;
/*
 * Use of this route would involve computing A*x+B*y and C*x+D*y,
 * which is 4 multiplications.  Simple division would be just A-q*B at
 * one division.  To account for this I pretend that I made no progress
 * at all if I would simulate less than 3 regular remainder steps.  This is
 * 3 rather than 4 because (maybe) the Lehmer code bundles up more work for
 * the overhead that it spends.
 */
        if (n < 3) ax = 1, ay = 0, bx = 0, by = 1;
        else if ((n & 1) != 0)
        {   ax = -ax;
            by = -by;
        }
        else
        {   ay = -ay;
            bx = -bx;
        }
/*
 * Copy results into the places where they are wanted.
 */
        *axp = ax;
        *ayp = ay;
        *bxp = bx;
        *byp = by;
        return;
    }
}   

static int32 huge_gcd(unsigned32 *a, int32 lena, unsigned32 *b, int32 lenb)
/*
 * A and B are vectors of unsigned integers, representing numbers with
 * radix 2^31.  lena and lenb indicate how many digits are present. The
 * numbers are unsigned.  This will use the vectors as workspace and
 * compute the GCD of the two integers.  The result handed back will
 * really consist of two parts.  The first is a flag (held in the top
 * bit) that indicates whether A and B were swopped.  The remaining bits
 * hold the length (remaining) of A.
 */
{
    unsigned32 a0, a1, a2, b0, b1;
    int flipped = 0;
/*
 * The next two lines adjust for an oddity in my bignum representation - the
 * if the leading digit would have its 0x40000000 bit set then I stick on
 * a leading zero.  This gives me a bit more in hand wrt signed values.
 */
    if (a[lena] == 0) lena--;
    if (b[lenb] == 0) lenb--;
    for (;;)
    {
        unsigned32 q;
        int32 lenr;
/*
 * I will perform reductions until the smaller of my two bignums has been
 * reduced to a single-precision value.  After that the tidying up to
 * obtain the true GCD will be fairly easy.
 * If one number is MUCH bigger than the other I will do (part of) a
 * regular remainder calculation to reduce it.  If the two numbers are
 * about the same size then I will combine several big-number operations
 * into one - the clever part of this entire program.
 */
        if (lena < lenb)
        {   unsigned32 *c = a;
            int32 lenc = lena;
            a = b; lena = lenb;
            b = c; lenb = lenc;
            flipped ^= 1;
        }
        if (lenb == 0) break;    /* B (at least) is now single precision */
        else if (lena == lenb)
        {   while (lenb >= 0 && a[lenb] == b[lenb]) lenb--;
/*
 * Here I want to ensure that A is really at least as big as B.  While
 * so doing I may happen to discover that they are actually the same value.
 * If I do that I set things so that B looks like a single precision zero
 * and exit from the loop.  The result will be that A gets returned as the
 * GCD.
 */
            if (lenb < 0)
            {   b[0] = 0;
                lenb = 0;
                break;
            }
            if (a[lenb] < b[lenb])
            {   unsigned32 *c = a;  /* NB do not swop lena, lenb here      */
                a = b;              /* since lenb has been used as scratch */
                b = c;              /* and both numbers are lena long      */
                flipped ^= 1;
            }
/*
 * Since the shorter number was double-length (at least) it is OK to
 * grab the first two digits of each.
 */
            a0 = a[lena]; a1 = a[lena-1];
            b0 = b[lena]; b1 = b[lena-1];
            lenb = lena;
            goto lehmer;
        }
        else if (lena == lenb+1)
        {   a0 = a[lena]; a1 = a[lenb];
            b0 = 0;       b1 = b[lenb];
/*
 * If one number has one more digit than the other but the quotient will
 * still be small I may be able to use the Lehmer code.
 */
            if (a0 < b1) goto lehmer;
        }
/*
 * Here I need to do one step towards reduction by division.  A is
 * at leat as long as B, and B has at least two digits.
 */
    reduce_by_division:
        a0 = a[lena];    a1 = a[lena-1];
        b0 = b[lenb];    b1 = b[lenb-1];
        if (lena > 1)    a2 = a[lena-2];
        else             a2 = 0;
/*
 * Now I intend to estimate A/B by computing (a0,a1,a2)/(b0,b1).  To do
 * this I will first shift the leading digits of A and B right until b0
 * vanishes, then I will just need to compute (a0,a1,a2)/b1.  If this
 * would overflow, I compute (a0,a1)/b1 instead.
 */
        while (b0 != 0)
        {   b1 = b1 >> 1;
            if ((b0 & 1) != 0) b1 |= 0x40000000;
            b0 = b0 >> 1;
            a2 = a2 >> 1;
            if ((a1 & 1) != 0) a2 |= 0x40000000;
            a1 = a1 >> 1;
            if ((a0 & 1) != 0) a1 |= 0x40000000;
            a0 = a0 >> 1;
        }
        lenr = lena;
        if (b1 == 0x7fffffff)
/*
 * I make b1 = 0x7fffffff a special case because (a) then B is as well-
 * normalised as it possibly can be and so maybe my estimated quotient
 * should be quite accurate and (b) I want to ensure that the estimate
 * for q that I obtain here is an UNDER-estimate (if anything), and I
 * will achieve this by knowing that A has been rounded down a bit and by
 * rounding B up.  This rounding will mean that in general each reduction
 * step here will be able to remove 29 or 30 bits from the difference
 * between the lengths of A and B.  I hope that getting q more accurate
 * would not justify the extra effort.  My worry is that regard is that
 * maybe a couple of bits of error on one step will over-often lead to
 * the very next q having to be just 1 or 2 in value, which would represent
 * not very much progress in the step.  My main justification for taking
 * a relaxed view is that except for the very first step in the remainder
 * sequence it will be very uncommon for this code to be activated.
 */
        {   if (a0 != 0) q = a0;
            else if (lena == lenb) q = 1;
            else q = a1, lenr--;
        }
        else
        {   unsigned32 rtemp, qtemp;
            b1++;         /* To achieve rounding down of q */
            if (a0 != 0 || a1 >= b1) Ddivide(rtemp, qtemp, a0, a1, b1);
/*
 * The following line indicates a special case needed when this division
 * is almost done - up to almost the end I can afford to approximate a
 * true quotient (1,0,...) as (0,ffffffff,...), but eventually I must
 * grit my teeth and get things right.  Since I have carefully tested and
 * ensured that A>B I KNOW that the true quotient is at least 1, so when
 * lena==lenb I can force this is if I was in danger of estimating a lower
 * value.
 */
            else if (lena == lenb) qtemp = 1;
            else { Ddivide(rtemp, qtemp, a1, a2, b1); lenr--; }
            q = qtemp;
        }
/*
 * Now q is an approximation to the leading digit of the quotient.
 * I now want to replace a by a - q*b*r^(lenr-lenb).
 */
        {   unsigned32 carry = 0, carry1 = 1;
            int32 i, j;
            for (i=0, j=lenr-lenb; i<=lenb; i++, j++)
            {   unsigned32 mlow, w;
                Dmultiply(carry, mlow, b[i], q, carry);
                w = a[j] + clear_top_bit(~mlow) + carry1;
                if ((int32)w < 0)
                {   w = clear_top_bit(w);
                    carry1 = 1;
                }
                else carry1 = 0;
                a[j] = w;
            }
            a[j] = a[j] + (~carry) + carry1;
        }
        while (lena > 0 && a[lena]==0) lena--;
        continue;

    lehmer:
        {   int32 ax, ay, bx, by, i;
            {   int32 axt, ayt, bxt, byt;
                unsigned32 b00 = b0;
/*
 * If the numbers have 3 digits available and if the leading digits are
 * small I do some (minor) normalisation by shifting up by 16 bits.  This
 * should increase the number of steps that can be taken at once (slightly).
 */
                if (a0 < (int32)0x8000U && lena > 2)
                {   a0 = (a0 << 16) | (a1 >> 15);
                    a1 = ((a1 << 16) | (a[lena-2] >> 15)) & 0x7fffffff;
                    b00 = (b00 << 16) | (b1 >> 15);
                    b1 = ((b1 << 16) | (b[lena-2] >> 15)) & 0x7fffffff;
                }
                next_gcd_step(a0, a1, b00, b1,
                              &axt, &ayt, &bxt, &byt);
                ax = axt; ay = ayt;
                bx = bxt; by = byt;
                if (ay == 0) goto reduce_by_division;
            }
/*
 * Now we should be able to arrange
 *   [ ax  ay ]  =  [ >0    <= 0 ]
 *   [ bx  by ]     [ <= 0  > 0  ]
 * and I swop the rows to ensure that this is so.
 */
            if (ax < 0 || by < 0)
            {   int32 cx = ax, cy = ay;
                ax = bx; ay = by;
                bx = cx; by = cy;
            }
            ay = -ay;
            bx = -bx;    /* Now all variables are positive */
/*
 * Now I want to compute ax*a - ay*b
 *                   and by*b - bx*a
 * and use these values for the new a and b.  Remember that at present
 * a and b are just about the same length, and provided that I use b0
 * for the leading digit of b I can treat both as having length lena
 */
            {   unsigned32 carryax = 0, carryay = 0,
                           carrybx = 0, carryby = 0,
                           borrowa = 1, borrowb = 1,
                           aix, aiy, bix, biy, aa, bb;
                for (i=0; i<lena; i++)
                {   Dmultiply(carryax, aix, a[i], ax, carryax);
                    Dmultiply(carryay, aiy, b[i], ay, carryay);
                    Dmultiply(carrybx, bix, a[i], bx, carrybx);
                    Dmultiply(carryby, biy, b[i], by, carryby);
                    aa = aix + clear_top_bit(~aiy) + borrowa;
                    bb = biy + clear_top_bit(~bix) + borrowb;
                    borrowa = aa >> 31;
                    borrowb = bb >> 31;
                    a[i] = clear_top_bit(aa);
                    b[i] = clear_top_bit(bb);
                }
/*
 * I do the top digit by hand to cope with a possible virtual zero digit at
 * the head of B.
 */
                Dmultiply(carryax, aix, a[lena], ax, carryax);
                Dmultiply(carryay, aiy, b0, ay, carryay);
                Dmultiply(carrybx, bix, a[lena], bx, carrybx);
                Dmultiply(carryby, biy, b0, by, carryby);
                aa = aix + clear_top_bit(~aiy) + borrowa;
                bb = biy + clear_top_bit(~bix) + borrowb;
                borrowa = aa >> 31;
                borrowb = bb >> 31;
                aa = clear_top_bit(aa);
                bb = clear_top_bit(bb);
                a[lena] = aa;
                if (b0 != 0) b[lena] = bb;
                lenb = lena;
                if (b0 == 0) lenb--;
/*
 * The following test is here as a provisional measure - it caught a number of
 * bugs etc while I was developing this code.  My only worry is that maybe
 * the carries and borrows could (correctly) combine to leave zero
 * upper digits here without the exact equalities tested here happening.
 * I will remove this test after a decent interval.
 */
                if (carryax - carryay + borrowa != 1 ||
                    carryby - carrybx + borrowb != 1)
                {   err_printf("Carries %d \"%s\" %ld %ld %ld %ld %ld %ld\n",
                             __LINE__, __FILE__,
                             (long)carryax, (long)carryay, (long)carrybx,
                             (long)carryby, (long)borrowa, (long)borrowb);
                    my_exit(EXIT_FAILURE);
                }
                while (lena > 0 && a[lena] == 0) lena--;
                while (lenb > 0 && b[lenb] == 0) lenb--;
            }
        }
        continue;
    }
    if (flipped) lena |= ~0x7fffffff;
    return lena;
}

Lisp_Object gcd(Lisp_Object a, Lisp_Object b)
{
    int32 p, q;
    if (is_fixnum(a))
    {   if (!is_fixnum(b))
        {   if (is_numbers(b) && is_bignum(b))
            {   if (a == fixnum_of_int(0)) return absb(b);
                else b = rembi(b, a);
/*
 * a is a fixnum here, so did not need to be stacked over the
 * call to rembi()
 */
            }
            else return aerror2("bad arg for gcd", a, b);
        }
    }
    else if (is_numbers(a) && is_bignum(a))
    {   if (is_fixnum(b))
        {   if (b == fixnum_of_int(0)) return absb(a);
            else a = rembi(a, b);
        }
        else if (is_numbers(b) && is_bignum(b))
        {   Lisp_Object nil;
/*
 * Now I have a case that maybe I hope is not too common, but which may
 * count as the interesting one - the GCD of two bignums.  First I ensure
 * that the inputs have been made positive and also that I have made copies
 * of them - this latter condition is so that it will be proper for me
 * to perform remaindering operations on them in-place, thereby reducing the
 * total turn-over of memory that I incur.
 */
            push(b);
            if (bignum_minusp(a)) a = negateb(a);
            else a = copyb(a);
            pop(b);
            errexit();
            push(a);
            if (bignum_minusp(b)) b = negateb(b);
            else b = copyb(b);
            pop(a);
            errexit();
/*
 * Note that negating a NEGATIVE bignum may sometimes make it grow by one
 * word, but can never cause it to shrink - and in particular never shrink to
 * a smallnum.  Of course negating a positive bignum can (in just one case!)
 * give a fixnum - but that can not occur here.
 */
            {
                int32 lena, lenb, new_lena;
                unsigned32 b0;
/*
 * I apply two ideas here.  The first is to perform all my arithmetic
 * in-place, since I have ensured that the numbers I am working with are
 * fresh copies.  The second is to defer true bignum operations for as
 * long as I can by starting a remainder sequence using just the leading
 * digits of the inputs.
 */
                lena = (bignum_length(a) >> 2) - 2;
                lenb = (bignum_length(b) >> 2) - 2;
                new_lena = huge_gcd(&bignum_digits(a)[0], lena,
                                    &bignum_digits(b)[0], lenb);
/*
 * The result handed back (new_lena here) contains not only the revised
 * length of a, but also a flag bit (handed back in its sign bit) to
 * indicate whether A and B have been swopped.
 */
                if (new_lena < 0)
                {   Lisp_Object c = a;
                    a = b;
                    b = c;
                    new_lena = clear_top_bit(new_lena);
                }
/*
 * By this stage I have reduced A and B so that B is a single-precision
 * bignum (i.e. its value is at most 0x7fffffff).  A special case will be
 * when B==0.  To complete the GCD process I need to do a single remainder
 * operation (A%B) after which I have just machine arithmetic to do to
 * complete the job.
 */
                b0 = bignum_digits(b)[0];
                if (b0 == 0)
                {   int32 a0 = bignum_digits(a)[new_lena];
/*
 * The leading digit of a bignum is in effect one bit shorter than the
 * others (to allow for the fact that it is signed).  In huge_gcd I did
 * not worry about that, but here (before I return) I need to restore a
 * proper state.  Note that since the GCD is no larger than either original
 * number I am guaranteed to have space to put the padding zero I may need
 * to stick onto the number...
 */
                    if ((a0 & 0x40000000) != 0)
                        bignum_digits(a)[++new_lena] = 0;
                    lena = (bignum_length(a) >> 2) - 2;
                    numhdr(a) = make_bighdr(new_lena+2);
                    lena = (lena + 1) & 0xfffffffeU;
                    new_lena = (new_lena + 1) & 0xfffffffeU;
                    if (new_lena != lena)
                        bignum_digits(a)[new_lena+1] =
                            make_bighdr(lena - new_lena);
                    return a;
                }
/*
 * Another special case is if we have just discovered that the numbers were
 * co-prime.
 */
                else if (b0 == 1) return fixnum_of_int(1);
                p = bignum_digits(b)[0];
                if (new_lena == 0) q = bignum_digits(a)[0];
                else
                {   q = bignum_digits(a)[new_lena] % p;
                    while (new_lena > 0)
                    {   unsigned32 qtemp;
                        Ddivide(q, qtemp, q,
                                bignum_digits(a)[--new_lena], p);
                    }
                }
                if (p < q)
                {   int32 r = p;
                    p = q;
                    q = r;
                }
                goto gcd_using_machine_arithmetic;
            }
/*
 * The next 4 lines seem to be orphan code, no longer reachable.
            if (b == fixnum_of_int(0)) return a;
            a = rembi(a, b);
            errexit();
 */
        }
        else return aerror2("bad arg for gcd", a, b);
    }
    else return aerror2("bad arg for gcd", a, b);
/*
 * If I drop out of the above IF statement I have reduced a and b to
 * fixnums, which I can compute with directly using C native arithmetic.
 */
    p = int_of_fixnum(a);
    q = int_of_fixnum(b);
    if (p < 0) p = -p;
    if (q < 0) q = -q;
gcd_using_machine_arithmetic:
#ifndef FAST_DIVISION
/*
 * If your computer has a slow implementation of the C remainder
 * operation (p % q) but fast shifts then it may be worthwhile
 * implementing integer GCD thusly...  On an ARM where division is
 * done in software my time tests showed the shift-and-subtract GCD
 * code over twice as fast as the version using the remainder operator.
 * Somewhat to my amazement, most other targets (at least when I use -O
 * to optimise this code) show this version faster than the more
 * obvious code.  See also the discussion in Knuth vol II.
 */
    if (p == 0) p = q;
    else if (q != 0)
    {   int twos = 0;
/*
 * I shift p and q right until both are odd numbers, counting the
 * power of two that was needed for the GCD.
 * The contorted code here tries to avoid redundant tests on the
 * bottom bits of p and q.
 */
        for (;;)
        {   if ((p & 1) == 0)
            {   if ((q & 1) == 0)
                {   p = p >> 1;
                    q = q >> 1;
                    twos++;
                    continue;
                }
                do p = p >> 1; while ((p & 1) == 0);
                break;
            }
            while ((q & 1) == 0) q = q >> 1;
            break;
        }
/*
 * Now p and q are both odd, so if I subtract one from the other
 * I get an even number that can properly be shifted right (because
 * multiples of 2 have already all be taken care of).  On some RISC
 * architectures this test-and-subtract loop will run only a bit slower
 * than just one division operation, especially if the two numbers p and
 * q are small.
 */
        while (p != q)
        {   if (p > q)
            {   p = p - q;
                do p = p >> 1; while ((p & 1) == 0);
            }
            else
            {   q = q - p;
                do q = q >> 1; while ((q & 1) == 0);
            }
        }
/*
 * Finally I must re-instate the power of two that was taken out
 * earlier.
 */
        p = p << twos;
    }
#else /* FAST_DIVISION */
    if (p < q)
    {   int32 t = p;
        p = q;
        q = t;
    }
    while (q != 0)
    {   int32 t = p % q;
        p = q;
        q = t;
    }
#endif /* FAST_DIVISION */
/*
 * In some cases the result will be a bignum.  Even with fixnum inputs
 * gcd(-0x08000000, -0x08000000) == 0x08000000 which is a bignum. Yuk!
 * What is worse, in the case that I get here out of the gcd(big,big) code
 * I can end up with a value that needs to be a 2-word bignum - that happens
 * when the result is of the form #b01xx...
 */
    if ((p & 0x40000000) != 0) return make_two_word_bignum(0, p);
    else if (p >= 0x08000000) return make_one_word_bignum(p);
    else return fixnum_of_int(p);
}

Lisp_Object lcm(Lisp_Object a, Lisp_Object b)
{
    Lisp_Object g, nil = C_nil;
    if (a == fixnum_of_int(0) ||
        b == fixnum_of_int(0)) return fixnum_of_int(0);
    stackcheck2(0, a, b);
    push2(a, b);
    g = gcd(a, b);
    errexitn(2);
    pop(b);
    b = quot2(b, g);
    errexitn(1);
/*
 * b has already been through quot2(), so minusp can not fail...
 */
    if (minusp(b)) b = negate(b);
    pop(a);
    errexit();
    if (minusp(a))  /* can not fail */
    {   push(b);
        a = negate(a);
        pop(b);
    }
    errexit();
    return times2(a, b);
}

Lisp_Object lognot(Lisp_Object a)
{
/*
 * bitwise negation can never cause a fixnum to need to grow into
 * a bignum.  For bignums I implement ~a as -(a+1).
 */
    if (is_fixnum(a)) return (Lisp_Object)((int32)a ^ ((-1) << 4));
    else if (is_numbers(a) && is_bignum(a))
    {   Lisp_Object nil;
        a = plus2(a, fixnum_of_int(1));
        errexit();
        return negate(a);
    }
    else return aerror1("Bad arg for xxx",  a);
}

#ifdef __powerc
/* If you have trouble compiling this just comment it out, please */
   #pragma options(!global_optimizer)
#endif

Lisp_Object ash(Lisp_Object a, Lisp_Object b)
/*
 * Shift A left if B is positive, or right if B is negative.  Right shifts
 * are arithmetic, i.e. as if 2s-complement values are used with negative
 * values having an infinite number of leading '1' bits.
 */
{
    int32 bb;
    if (!is_fixnum(b)) return aerror2("bad arg for lshift", a, b);
    bb = int_of_fixnum(b);
    if (bb == 0) return a;        /* Shifting by zero has no effect */
    if (is_fixnum(a))
    {   int32 aa = int_of_fixnum(a);
        if (aa == 0) return a;    /* Shifting zero leaves it unaltered */
        if (bb < 0)
        {   bb = -bb;
/*
 * Fixnums have only 28 data bits in them, and so right shifts by more than
 * that will lead to a result that is all 1s or all 0s.  If I assume that
 * I am working with 32 bit words I can let a shift by 30 bits achieve this
 * effect.
 */
            if (bb > 30) bb = 30;
#ifdef SIGNED_SHIFTS_ARE_LOGICAL
/*
 * ANSI C (oh bother it) permits an implementation to have right shifts
 * on signed values as logical (ie. shifting in zeros into the vacated
 * positions.  In that case since I really want an arithmetic shift here
 * I need to insert '1' bits by hand.
 */
            if (aa < 0)
            {   aa = aa >> bb;
                aa |= (((int32)-1) << (32 - bb));
            }
            else
#endif
            aa = aa >> bb;
            return fixnum_of_int(aa);
        }
        else if (bb < 31)
        {   int32 ah = aa >> (31 - bb);
#ifdef SIGNED_SHIFTS_ARE_LOGICAL
            if (aa < 0) ah |= (((int32)-1) << (bb+1));
#endif
            aa = aa << bb;
/*
 * Here (ah,aa) is a double-precision representation of the left-shifted
 * value.  Note that this has just 31 valid bits in aa (but I have not
 * yet masked the top bit down to zero). Because a fixnum has only 28 bits
 * this can be at worst a 2-word bignum.  But it may be a 1-word bignum or
 * a fixnum, and I can spend much effort deciding which!
 */
            if (ah == 0 && aa >= 0 && aa < 0x40000000)
            {   if (aa < 0x08000000) return fixnum_of_int(aa);
                else return make_one_word_bignum(aa);
            }
            else if (ah == -1 && aa < 0 && aa >= -0x40000000)
            {   if (aa >= -0x08000000) return fixnum_of_int(aa);
                else return make_one_word_bignum(aa);
            }
            return make_two_word_bignum(ah, clear_top_bit(aa));
        }
        else
        {
            Lisp_Object nil;
/*
 * I drop through to here for a left-shift that will need to give a
 * bignum result, since the shift will be by at least 31 and the value
 * being shifted was non-zero.  I deal with this by making the input into
 * bignum representation (though it would not generally be valid as one),
 * and dropping through to the general bignum shift code.
 */
            a = make_one_word_bignum(aa);
            errexit();
/*
 * DROP THROUGH from here and pick up the general bignum shift code
 */
        }
    }
    else if (!is_numbers(a) || !is_bignum(a))
        return aerror2("bad arg for lshift", a, b);
/*
 * Bignum case here
 */
    if (bb > 0)
    {   int32 lena = (bignum_length(a) >> 2)-2;
        int32 words = bb / 31;    /* words to shift left by */
        int32 bits = bb % 31;     /* bits to shift left by  */
        int32 msd = bignum_digits(a)[lena];
        int32 d0 = msd >> (31 - bits);
        int32 d1 = clear_top_bit(msd << bits);
        int32 i, lenc = lena + words;
        CSLbool longer = NO;
        Lisp_Object c, nil;
#ifdef SIGNED_SHIFTS_ARE_LOGICAL
        if (msd < 0) d0 |= (((int32)-1) << (bits+1));
#endif
        if (!((d0 == 0 && (d1 & 0x40000000) == 0) ||
              (d0 == -1 && (d1 & 0x40000000) != 0)))
            lenc++, longer = YES;
        push(a);
        c = getvector(TAG_NUMBERS, TYPE_BIGNUM, (lenc+2)<<2);
        pop(a);
        errexit();
/*
 * Before I do anything else I will fill the result-vector with zero, so that
 * the parts that do not get A copied in will end up in a proper state.  This
 * should include the word that pads the vector out to an even number of
 * words.
 */
        for (i=0; i<=lenc; i++) bignum_digits(c)[i] = 0;
        if ((lenc & 1) != 0) bignum_digits(c)[i] = 0; /* The spare word */
        d0 = 0;
        for (i=0; i<=lena; i++)
        {   d1 = bignum_digits(a)[i];
/*
 * The value of d0 here is positive, so there are no nasty issues of
 * logical vs arithmetic shifts to bother me.
 */
            bignum_digits(c)[words + i] =
                (d0 >> (31 - bits)) | clear_top_bit(d1 << bits);
            d0 = d1;
        }
        if (longer)
        {   bignum_digits(c)[words+i] = d0 >> (31 - bits);
#ifdef SIGNED_SHIFTS_ARE_LOGICAL
            if (d0 < 0) bignum_digits(c)[words+i] |= (((int32)-1) << (bits+1));
#endif
        }
        else if (msd < 0) bignum_digits(c)[words+i-1] |= ~0x7fffffff;
        return c;
    }
    else
/*
 * Here for bignum right-shifts.
 */
    {   int32 lena = (bignum_length(a) >> 2)-2;
        int32 words = (-bb) / 31;    /* words to shift right by */
        int32 bits = (-bb) % 31;     /* bits to shift right by  */
        int32 msd = bignum_digits(a)[lena];
        int32 d0 = msd >> bits;
        int32 d1 = clear_top_bit(msd << (31 - bits));
        int32 i, lenc = lena - words;
        CSLbool shorter = NO;
        Lisp_Object c, nil;
#ifdef SIGNED_SHIFTS_ARE_LOGICAL
        if (msd < 0) d0 |= (((int32)-1) << (31 - bits));
#endif
        if (bits != 0 &&
            ((d0 == 0 && (d1 & 0x40000000) == 0) ||
             (d0 == -1 && (d1 & 0x40000000) != 0)))
            lenc--, shorter = YES;
/*
 * Maybe at this stage I can tell that the result will be zero (or -1).
 * If the result will be a single-precision value I will nevertheless
 * build it in a one-word bignum and then (if appropriate) extract the
 * fixnum value.  This is slightly wasteful, but I do not (at present)
 * view right-shifting a bignum to get a fixnum as super speed-critical.
 */
        if (lenc < 0) return fixnum_of_int(msd < 0 ? -1 : 0);
        push(a);
        c = getvector(TAG_NUMBERS, TYPE_BIGNUM, (lenc+2)<<2);
        pop(a);
        errexit();
        if ((lenc & 1) != 0) bignum_digits(c)[lenc+1] = 0;/* The spare word */
        d0 = bignum_digits(a)[words];
        for (i=0; i<lenc; i++)
        {   d1 = bignum_digits(a)[words+i+1];
            bignum_digits(c)[i] =
                (d0 >> bits) | clear_top_bit(d1 << (31 - bits));
            d0 = d1;
        }
        d1 = shorter ? msd : (msd < 0 ? -1 : 0);
        bignum_digits(c)[i] =
            (d0 >> bits) | (d1 << (31 - bits));
/*
 * Now I see if the result ought to be represented as a fixnum.
 */
        if (lenc == 0)
        {   d0 = bignum_digits(c)[0];
            d1 = d0 & (-0x08000000);
            if (d1 == 0 || d1 == -0x08000000) return fixnum_of_int(d0);
        }
/*
 * Drop through if a genuine bignum result is needed.
 */
        return c;
    }
}

#ifdef __powerc
/* If you have trouble compiling this just comment it out, please */
   #pragma options(global_optimizer)
#endif

Lisp_Object shrink_bignum(Lisp_Object a, int32 lena)
{   int32 msd = bignum_digits(a)[lena];
    int32 olen = lena;
    if (msd == 0)
    {   while (lena > 0)
        {   lena--;
            msd = bignum_digits(a)[lena];
            if (msd != 0) break;
        }
        if ((msd & 0x40000000) != 0) lena++;
    }
    else if (msd == -1)
    {   while (lena > 0)
        {   lena--;
            msd = bignum_digits(a)[lena];
            if (msd != 0x7fffffff) break;
        }
        if ((msd & 0x40000000) == 0) lena++;
    }
    if (lena == 0)
    {   int32 w = msd & 0x78000000;
        if (w == 0 || w == 0x78000000) return fixnum_of_int(msd);
    }
    if (lena == olen) return a;
/*
 * Here I had allocated too much space, so I have to trim it off and
 * put a dummy vector in to pad out the heap.
 */
    numhdr(a) -= pack_hdrlength(olen-lena);
    msd = bignum_digits(a)[lena];
    if ((msd & 0x40000000) != 0) bignum_digits(a)[lena] = msd | ~0x7fffffff;
    if ((lena & 1) != 0) bignum_digits(a)[++lena] = 0;
    lena++;
    olen = (olen+1)|1;
    if (lena == olen) return a;
    bignum_digits(a)[lena]=make_bighdr(olen-lena);
    return a;
}

static Lisp_Object logiorbb(Lisp_Object a, Lisp_Object b)
{   Lisp_Object nil;
    int32 lena, lenb, i, msd;
    errexit(); /* failure in make_one_word_bignum()? */
    lena = (bignum_length(a) >> 2) - 2;
    lenb = (bignum_length(b) >> 2) - 2;
    if (lena > lenb)
    {   Lisp_Object c = a;
        int32 lenc = lena;
        a = b; lena = lenb;
        b = c; lenb = lenc;
    }
    /* Now b is at least as long as a */
    msd = bignum_digits(a)[lena];
    if (msd < 0)
    {   push(b);
        a = copyb(a);
        pop(b);
        errexit();
        for (i=0; i<=lena; i++) bignum_digits(a)[i] |= bignum_digits(b)[i];
    }
    else
    {   push(a);
        b = copyb(b);
        pop(a);
        errexit();
        for (i=0; i<=lena; i++) bignum_digits(b)[i] |= bignum_digits(a)[i];
        if (lena != lenb) return b;
        a = b;
    }
    return shrink_bignum(a, lena);
}

static Lisp_Object logiorib(Lisp_Object a, Lisp_Object b)
{
    push(b);
    a = make_one_word_bignum(int_of_fixnum(a));
    pop(b);
    return logiorbb(a, b);
}

Lisp_Object logior2(Lisp_Object a, Lisp_Object b)
{
    if (is_fixnum(a))
    {   if (is_fixnum(b)) return (Lisp_Object)((int32)a | (int32)b);
        else if (is_numbers(b) && is_bignum(b)) return logiorib(a, b);
        else return aerror2("bad arg for logior", a, b);
    }
    else if (is_numbers(a) && is_bignum(a))
    {   if (is_fixnum(b)) return logiorib(b, a);
        else if (is_numbers(b) && is_bignum(b)) return logiorbb(a, b);
        else return aerror2("bad arg for logior", a, b);
    }
    else return aerror2("bad arg for logior", a, b);
}

static Lisp_Object logxorbb(Lisp_Object a, Lisp_Object b)
{   Lisp_Object nil;
    int32 lena, lenb, i;
    unsigned32 w;
    errexit();          /* failure in make_one_word_bignum()? */
    lena = (bignum_length(a) >> 2) - 2;
    lenb = (bignum_length(b) >> 2) - 2;
    if (lena > lenb)
    {   Lisp_Object c = a;
        int32 lenc = lena;
        a = b; lena = lenb;
        b = c; lenb = lenc;
    }
    /* Now b is at least as long as a */
    push(a);
    b = copyb(b);
    pop(a);
    errexit();
    for (i=0; i<lena; i++) bignum_digits(b)[i] ^= bignum_digits(a)[i];
    w = bignum_digits(a)[i];
    if (lena == lenb) bignum_digits(b)[i] ^= w;
    else
    {   bignum_digits(b)[i] ^= clear_top_bit(w);
        if ((w & 0x80000000U) != 0)
        {   for(i++; i<lenb; i++)
                bignum_digits(b)[i] = clear_top_bit(~bignum_digits(b)[i]);
            bignum_digits(b)[i] = ~bignum_digits(b)[i];
        }
    }
    return shrink_bignum(b, lenb);
}

static Lisp_Object logxorib(Lisp_Object a, Lisp_Object b)
{
    push(b);
    a = make_one_word_bignum(int_of_fixnum(a));
    pop(b);
    return logxorbb(a, b);
}

Lisp_Object logxor2(Lisp_Object a, Lisp_Object b)
{
    if (is_fixnum(a))
    {   if (is_fixnum(b))
            return (Lisp_Object)(((int32)a ^ (int32)b) + TAG_FIXNUM);
        else if (is_numbers(b) && is_bignum(b)) return logxorib(a, b);
        else return aerror2("bad arg for logxor", a, b);
    }
    else if (is_numbers(a) && is_bignum(a))
    {   if (is_fixnum(b)) return logxorib(b, a);
        else if (is_numbers(b) && is_bignum(b)) return logxorbb(a, b);
        else return aerror2("bad arg for logxor", a, b);
    }
    else return aerror2("bad arg for logxor", a, b);
}

Lisp_Object logeqv2(Lisp_Object a, Lisp_Object b)
{
    if (is_fixnum(a))
    {   if (is_fixnum(b))
            return (Lisp_Object)((int32)a ^ (int32)b ^
                                 (int32)fixnum_of_int(-1));
        else if (is_numbers(b) && is_bignum(b))
        {   push(b);
            a = make_one_word_bignum(~int_of_fixnum(a));
            pop(b);
            return logxorbb(a, b);
        }
        else return aerror2("bad arg for logeqv", a, b);
    }
    else if (is_numbers(a) && is_bignum(a))
    {   if (is_fixnum(b))
        {   push(a);
            b = make_one_word_bignum(~int_of_fixnum(b));
            pop(a);
            return logxorbb(b, a);
        }
        else if (is_numbers(b) && is_bignum(b))
        {   Lisp_Object nil;
            push(a);
            b = lognot(b);
            pop(a);
            errexit();
            return logxorbb(a, b);
        }
        else return aerror2("bad arg for logeqv", a, b);
    }
    else return aerror2("bad arg for logeqv", a, b);
}

static Lisp_Object logandbb(Lisp_Object a, Lisp_Object b)
{   Lisp_Object nil;
    int32 lena, lenb, i, msd;
    errexit();            /* failure in make_one_word_bignum()? */
    lena = (bignum_length(a) >> 2) - 2;
    lenb = (bignum_length(b) >> 2) - 2;
    if (lena > lenb)
    {   Lisp_Object c = a;
        int32 lenc = lena;
        a = b; lena = lenb;
        b = c; lenb = lenc;
    }
    /* Now b is at least as long as a */
    msd = bignum_digits(a)[lena];
    if (msd >= 0)
    {   push(b);
        a = copyb(a);
        pop(b);
        errexit();
        for (i=0; i<=lena; i++) bignum_digits(a)[i] &= bignum_digits(b)[i];
    }
    else
    {   push(a);
        b = copyb(b);
        pop(a);
        errexit();
        for (i=0; i<=lena; i++) bignum_digits(b)[i] &= bignum_digits(a)[i];
        if (lena != lenb) return b;
        a = b;
    }
    return shrink_bignum(a, lena);
}

static Lisp_Object logandib(Lisp_Object a, Lisp_Object b)
{
    push(b);
    a = make_one_word_bignum(int_of_fixnum(a));
    pop(b);
    return logandbb(a, b);
}

Lisp_Object logand2(Lisp_Object a, Lisp_Object b)
{
    if (is_fixnum(a))
    {   if (is_fixnum(b)) return (Lisp_Object)((int32)a & (int32)b);
        else if (is_numbers(b) && is_bignum(b)) return logandib(a, b);
        else return aerror2("bad arg for logand", a, b);
    }
    else if (is_numbers(a) && is_bignum(a))
    {   if (is_fixnum(b)) return logandib(b, a);
        else if (is_numbers(b) && is_bignum(b)) return logandbb(a, b);
        else return aerror2("bad arg for logand", a, b);
    }
    else return aerror2("bad arg for logand", a, b);
}

/* end of arith09.c */