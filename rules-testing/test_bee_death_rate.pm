const ENERGY = 10;
const POISONING = 10;
const LIFE = 20;

species B of [0, LIFE];                                                          /* Bee for natural death */
species BD;                                                                      /* Death Bee */

rule bee_natural_death for l in [1, LIFE]{
    B[l] -[(1/LIFE)]-> B[0]
}

measure n_bee = #B[0];

system nd = B[LIFE-1]<1>;