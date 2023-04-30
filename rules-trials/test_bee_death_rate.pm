const ENERGY = 10;
const POISONING = 10;

species W of [0, ENERGY]*[0, POISONING];                                         /* Workers */
species DW;                                                                      /* Death Bee */

const worker_mortality_rate = 0.35 ;

/*
Worker (W) dies:
    Add new entity in Death Worker (DW) specie;

Base rates:
    worker_mortality_rate

Impacts:
    POISONING level (High level of POISONING increase worker_mortality_rate)

*/
rule worker_dies for e in [0, ENERGY] and p in [0, POISONING] {
    W[e,p] -[ (1- e/ENERGY) * worker_mortality_rate + (4^(p - POISONING)) ]-> DW
}

measure n_worker = #W[e, p for e in [0,ENERGY] and p in [0,POISONING]];

system init = W[9, 0]<50>;