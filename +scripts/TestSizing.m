% scripts/TestSizing.m  (SCRIPT)

clear B777.ConstraintAnalysis
close all

adp = B777.ADP();
adp.TLAR = cast.TLAR.B777F();

[tw, ws] = B777.ConstraintAnalysis(adp);