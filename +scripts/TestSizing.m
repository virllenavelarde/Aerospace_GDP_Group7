% scripts/TestSizing.m  (SCRIPT)

clear; clc;
close all;

adp = B777.ADP();   %calling class ADP
adp.TLAR = cast.TLAR.TubeWing();    %change here bc obj. is defined in TLAR (cast)

[tw, ws] = B777.ConstraintAnalysis(adp); %B777 bc its under B777 folder