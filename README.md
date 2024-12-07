# DosLichen
Just a graphical layout, based on PTCGraph, of an old DOS-virus named Lichen. Written in Free Pascal.

# HowToUse
Firstly, you need to fpc, units cthreads, ptcGraph and ptcCrt installed on your system somehow.

Secondly, there are two important things need to know about:

    1. You can choose one of the premade (in LichensColors.inc) color gradients of your lichen, by simply defining one these keys:
      -dAqua, -dEmerald, -dBlueNViolet, -dRed, -dBlue, -dYellow, 
      -dGreen, -dGradient1(out of 5), -dGenericViolet.
    2. To make lichens grow randomly on your screen, define -dNoStatGrowth,
       otherwise -dNoStatGrowth, cause of this option it will have randomly
       chosen source of growth, since it is not ran out of cycles.
       
# Conclusion

I hope you'll enjoy it.
