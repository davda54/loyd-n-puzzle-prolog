%% Loydovu NxN-tici řeším s pomocí A* vyhledávání, které jako heuristiku používá manhattenovskou vzdálenost od cílového stavu
%%
%% Stav je reprezentován jako pětice Pozice-Hloubka-Cena-Posloupnost-Vystup, kde
%%  - Pozice je N*N-členný seznam
%%  - Hloubka je hloubka v prohledávání od startovní pozice
%%  - Cena je dolní odhad poctu tahu do cílové pozice
%%  - Posloupnost je akumulátor už prošlých pozic od startovního stavu
%%  - Vystup je akumulátor symbolů reprezentujících tahy
%%



%% INICIALIZACE VYHLEDÁVÁNÍ

vyres_std(Start, Druh, Vystup) :- sirka(Start, N),
                                  cil(N, Cil),
                                  vyres(Start, Cil, N, Druh, Vystup).

vyres(Start, Cil, N, Druh, Vystup) :- heuristika(Start, 0, N, Druh, Cena),
				      vynuluj_cache(),
                                      najdi([Start-0-Cena-[]-[]], Cil, N, Druh, Obraceny_vystup),
                                      reverse(Obraceny_vystup, Vystup).



%% A* SEARCH %%

najdi([Cil-_-_-_-Vystup | _], Cil, _, _, Vystup)         :- !.
najdi([Nejlevnejsi_Stav | Zbytek], Cil, N, Druh, Vystup) :- je_v_cache(Nejlevnejsi_Stav, N), !,
				                            najdi(Zbytek, Cil, N, Druh, Vystup).

najdi([Nejlevnejsi_Stav | Zbytek], Cil, N, Druh, Vystup) :- rozvetvi(Nejlevnejsi_Stav, N, Druh, Deti),
							    vloz_mnozinu_do_prioritni_fronty(Deti, Zbytek, Neprozkoumane),
							    pridej_do_cache(Nejlevnejsi_Stav, N),
							    najdi(Neprozkoumane, Cil, N, Druh, Vystup).


%% vyrobí množinu všech stavŮ, do kterych se lze dostat ze stavu *Rodic*
rozvetvi(Rodic-Hloubka_Rodice-_-A-Vystup, N, Druh, Deti) :- bagof(Dite-Hloubka_Ditete-Cena-[Dite|A]-[Symbol|Vystup],
							      ( Hloubka_Ditete is Hloubka_Rodice + 1,
								presun(Rodic, Dite, Symbol, N),
                                                                \+member(Dite, A),
								heuristika(Dite, Hloubka_Ditete, N, Druh, Cena)
							      ),
							      Deti).



%% PRIORITNÍ FRONTA %%

vloz_mnozinu_do_prioritni_fronty([], Fronta, Fronta).
vloz_mnozinu_do_prioritni_fronty([Prvek|Mnozina], Puvodni_fronta, Vysledna_fronta) :- vloz_prvek_do_prioritni_fronty(Prvek, Puvodni_fronta, Mezi_fronta),
										      vloz_mnozinu_do_prioritni_fronty(Mnozina, Mezi_fronta, Vysledna_fronta).

vloz_prvek_do_prioritni_fronty(Stav-_-_-_-_, [Stav-X-Y-Z-V|W], [Stav-X-Y-Z-V|W])                       :- !.
vloz_prvek_do_prioritni_fronty(Mensi_prvek, [Vetsi_prvek|Fronta], [Mensi_prvek, Vetsi_prvek|Fronta])   :- mensi(Mensi_prvek, Vetsi_prvek), !.
vloz_prvek_do_prioritni_fronty(Vetsi_prvek,[Mensi_prvek|Puvodni_fronta],[Mensi_prvek|Vysledna_fronta]) :- vloz_prvek_do_prioritni_fronty(Vetsi_prvek,Puvodni_fronta,Vysledna_fronta), !.
vloz_prvek_do_prioritni_fronty(Prvek, [], [Prvek]).

mensi( _-_-Mensi_cena-_-_ , _-_-Vetsi_cena-_-_ ) :- Mensi_cena =< Vetsi_cena.



%% DYNAMICKÁ CACHE %%

:- dynamic prozkoumane/1.

vynuluj_cache()          :- retractall(prozkoumane(_)).
pridej_do_cache(Stav, N) :- preved_na_klic(Stav, N, Klic), assert(prozkoumane(Klic)).
je_v_cache(Stav, N)      :- preved_na_klic(Stav, N, Klic), prozkoumane(Klic).

preved_na_klic(Seznam-_-_-_-_, N, Klic)              :- Velikost is N*N, preved_na_klic(Seznam, Velikost, 0, Klic).
preved_na_klic([], _, Klic, Klic).
preved_na_klic([Symbol|Zbytek], N, Akumulator, Klic) :- Novy_akumulator is Akumulator*N + Symbol,
                                                        preved_na_klic(Zbytek, N, Novy_akumulator, Klic).



%% HEURISTIKA - MANHATTANOVSKÁ VZDÁLENOST A LINEARNÍ KONFLIKT

heuristika(Stav, Hloubka, N, nejkratsi, Vysledek) :- !, vzdalenost(Stav, N, Vzdalenost), konflikt(Stav, N, Prehozeni), 
                                                     Vysledek is Hloubka + Vzdalenost + Prehozeni.

heuristika(Stav, Hloubka, N, libovolne, Vysledek) :- !, vzdalenost(Stav, N, Vzdalenost), konflikt(Stav, N, Prehozeni), 
                                                     Vysledek is Hloubka + 10*(Vzdalenost + 2*Prehozeni).


vzdalenost(Stav, N, Vzdalenost)                   :- vzdalenost(Stav,0, N, Vzdalenost).
vzdalenost([], _, _, 0).
vzdalenost([Policko|Zbytek], Pos, N, Vzdalenost)  :- vzdalenost_policka(Pos, Policko, N, D_1),
                                                     vzdalenost(Zbytek, Pos + 1, N, D_2),
                                                     Vzdalenost is D_2 + D_1.

vzdalenost_policka(_, 0, _, 0)                    :- !.
vzdalenost_policka(Pos, Policko, N, Vzdalenost)   :- index_na_souradnice(Pos, N, X, Y),
                                                     index_na_souradnice(Policko - 1, N, X2, Y2),
                                                     Vzdalenost is abs(X-X2) + abs(Y-Y2).


konflikt(Stav, N, Vzdalenost)                                  :- konflikt(Stav, 1, N, Vzdalenost).
konflikt(_, 0, _, 0)                                           :- !.
konflikt([Spravny_prvek|Zbytek], Spravny_prvek, N, Vzdalenost) :- !, Dalsi_prvek is (Spravny_prvek + 1) mod (N*N), 
                                                                  konflikt(Zbytek, Dalsi_prvek, N, Vzdalenost).
konflikt([Prvek|Zbytek], Spravny_prvek, N, Vzdalenost)         :- Prvek > Spravny_prvek,
                                                                  (Prvek // N =:= Spravny_prvek // N; Prvek mod N =:= Spravny_prvek mod N), %% stejný řádek/sloupec
                                                                  Index is Prvek - Spravny_prvek,
                                                                  nth1(Index, Zbytek, Spravny_prvek),
                                                                  !,
                                                                  Dalsi_prvek is (Spravny_prvek + 1) mod (N*N), 
                                                                  konflikt(Zbytek, Dalsi_prvek, N, Zbyla_vzdalenost),
                                                                  Vzdalenost is Zbyla_vzdalenost + 2.
konflikt([_|Zbytek], Spravny_prvek, N, Vzdalenost)             :- Dalsi_prvek is (Spravny_prvek + 1) mod (N*N), 
                                                                  konflikt(Zbytek, Dalsi_prvek, N, Vzdalenost).



%% ZMĚNA STAVU %%

index_na_souradnice(Index, N, X, Y) :- X is Index mod N,
                                       Y is Index // N.

swap(Puvodni_Stav, Pozice_na_vymenu, Novy_Stav) :- nth0(Pozice_na_vymenu, Puvodni_Stav, Symbol_na_vymenu),
                                                   select(Symbol_na_vymenu, Puvodni_Stav, meziSymbol, TmpStav_1),
                                                   select(0, TmpStav_1, Symbol_na_vymenu, TmpStav_2),
                                                   select(meziSymbol, TmpStav_2, 0, Novy_Stav).

presun(Puvodni, Novy, Smer, N) :- nth0(Volna_pozice, Puvodni, 0),
                                  index_na_souradnice(Volna_pozice, N, X, Y),
                                  ( X > 0, Presouvana_pozice is Volna_pozice - 1, Smer = p;
                                    X < N - 1, Presouvana_pozice is Volna_pozice + 1, Smer = l;
                                    Y > 0, Presouvana_pozice is Volna_pozice - N, Smer = d;
                                    Y < N - 1, Presouvana_pozice is Volna_pozice + N, Smer = n
                                  ),
                                  swap(Puvodni, Presouvana_pozice, Novy).



%% POMOCNÉ PREDIKÁTY %%

sirka(Pole, Sirka) :- length(Pole, Delka), Sirka is floor(sqrt(Delka)).

cil(N, Cilovy_stav)                         :- Velikost is N*N, 
                                               cil(Velikost, Velikost, [], Cilovy_stav).
cil(_, 0, Akumulator, Akumulator)           :- !.
cil(Velikost, I_1, Akumulator, Cilovy_stav) :- I_2 is I_1 - 1, 
                                               Symbol is I_1 mod Velikost, 
                                               cil(Velikost, I_2, [Symbol | Akumulator], Cilovy_stav).



%% TESTY %%

%% volaji se buď s parametrem "libovolne" (pro rychle nalezeni libovolneho reseni), 
%% nebo s parametrem "nejkratsi" (pro nalezení nejkratšího řešení, což je NP-úplný problém).

test3_5(Druh_reseni)   :- ukaz_reseni([3,0, 2,1], Druh_reseni).
test3_6(Druh_reseni)   :- ukaz_reseni([0,3, 2,1], Druh_reseni).


test8_0(Druh_reseni)   :- ukaz_reseni([1,2,3, 4,5,6, 7,8,0], Druh_reseni).
test8_1(Druh_reseni)   :- ukaz_reseni([1,2,3, 4,5,6, 7,0,8], Druh_reseni).
test8_10(Druh_reseni)  :- ukaz_reseni([5,8,2, 1,0,3, 4,7,6], Druh_reseni).
test8_15(Druh_reseni)  :- ukaz_reseni([8,0,2, 5,7,3, 1,4,6], Druh_reseni).
test8_20(Druh_reseni)  :- ukaz_reseni([8,7,0, 5,4,2, 1,6,3], Druh_reseni).
test8_22(Druh_reseni)  :- ukaz_reseni([2,4,3, 5,1,7, 0,6,8], Druh_reseni).
test8_25(Druh_reseni)  :- ukaz_reseni([8,4,7, 0,6,2, 5,1,3], Druh_reseni).
test8_31(Druh_reseni)  :- ukaz_reseni([8,6,7, 2,5,4, 3,0,1], Druh_reseni).


test15_1(Druh_reseni)  :- ukaz_reseni([1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,0,15], Druh_reseni).
test15_10(Druh_reseni) :- ukaz_reseni([1,3,4,8, 6,2,7,0, 5,9,11,12, 13,10,14,15], Druh_reseni).
test15_19(Druh_reseni) :- ukaz_reseni([1,2,3,4, 5,6,7,8, 9,10,11,12, 0,14,15,13], Druh_reseni).
test15_23(Druh_reseni) :- ukaz_reseni([1,2,3,4, 5,6,7,8, 9,11,12,10, 0,14,15,13], Druh_reseni).
test15_29(Druh_reseni) :- ukaz_reseni([1,2,3,4, 5,6,7,8, 11,12,9,10, 0,14,15,13], Druh_reseni).
test15_30(Druh_reseni) :- ukaz_reseni([0,2,3,4, 1,6,7,8, 5,12,9,10, 11,14,15,13], Druh_reseni).
test15_33(Druh_reseni) :- ukaz_reseni([2,3,4,0, 1,6,7,8, 5,12,9,10, 11,14,15,13], Druh_reseni).
test15_35(Druh_reseni) :- ukaz_reseni([6,5,8,2, 3,7,15,4, 10,9,12,1, 13,14,0,11], Druh_reseni).
test15_40(Druh_reseni) :- ukaz_reseni([11,4,5,3, 2,7,8,12, 13,14,0,1, 10,6,9,15], Druh_reseni).
test15_80(Druh_reseni) :- ukaz_reseni([0,12,9,13, 15,11,10,13, 3,7,2,5, 4,8,6,1], Druh_reseni).


test24_1(Druh_reseni)  :- ukaz_reseni([1,2,3,4,5, 6,7,8,9,10, 11,12,13,14,15, 16,17,18,19,0, 21,22,23,24,20], Druh_reseni).
test24_6(Druh_reseni)  :- ukaz_reseni([1,2,3,4,5, 6,7,8,9,10, 0,11,12,13,14, 16,17,18,19,15, 21,22,23,24,20], Druh_reseni).
test24_20(Druh_reseni) :- ukaz_reseni([1,2,3,4,5, 6,7,8,9,10, 11,12,13,14,15, 16,17,18,19,20, 0,21,23,24,22], Druh_reseni).
test24_26(Druh_reseni) :- ukaz_reseni([1,2,3,4,5, 6,7,8,9,10, 11,12,13,14,15, 16,17,20,18,19, 0,21,23,24,22], Druh_reseni).


test35_1(Druh_reseni)  :- ukaz_reseni([1,2,3,4,5,6, 7,8,9,10,11,12, 13,14,15,16,17,18, 19,20,21,22,23,24, 25,26,27,28,29,30, 31,32,33,34,0,35], Druh_reseni).
test35_7(Druh_reseni)  :- ukaz_reseni([1,2,3,4,5,6, 7,8,9,10,11,12, 13,14,15,16,17,18, 0,19,20,21,22,23, 25,26,27,28,29,24, 31,32,33,34,35,30], Druh_reseni).
test35_21(Druh_reseni) :- ukaz_reseni([1,2,3,4,5,6, 7,8,9,10,11,12, 13,14,15,16,17,18, 19,20,21,22,23,24, 25,26,27,28,29,30, 0,31,32,34,35,33], Druh_reseni).


ukaz_reseni(Uvodni_stav, Druh_reseni) :- vyres_std(Uvodni_stav, Druh_reseni, X),length(X,N), write(N), write(' '), write(X).
