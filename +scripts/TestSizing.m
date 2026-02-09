%test run

adp = B777.ADP();
adp.TLAR = cast.TLAR.B777F();
[tw, ws] = B777.ConstraintAnalysis(adp);