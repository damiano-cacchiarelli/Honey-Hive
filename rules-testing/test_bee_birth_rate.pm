const ENERGY = 10;                                      /* The energy available to a bee */
const POISONING = 10;

species Q of [0, ENERGY];                               /* Queen */
species W of [0, ENERGY]*[0, POISONING];                /* Workers */
species DW;                                                                      /* Death Bee */

const worker_birth_rate = 0.9 ;

const worker_mortality_rate = 0.35 ;

param workers = 5;

/* 
Queen generate a Worker (WR):
    Drecrease ENERGY;
    Increase number of Worker;

Base rates: 
    worker_birth_rate;

Impacts: 
    Residual ENERGY (Low ENERGY decrease worker_birth_rate);
    Number of Worker (High number of Worker decrease worker_birth_rate);
    Residual NECTAR (N) (Low NECTAR decrease worker_birth_rate);
*/
rule queen_generate_worker for e in [1, ENERGY] {
    Q[e] -[ worker_birth_rate * 1.7^(e-ENERGY)  ]-> Q[e] | W[ENERGY-1, 0]
}


/*
Worker (W) dies:
    Add new entity in Death Worker (DW) specie;

Base rates:
    worker_mortality_rate

Impacts:
    POISONING level (High level of POISONING increase worker_mortality_rate)

*/
rule worker_dies for e in [0, ENERGY] and p in [0, POISONING] {
    W[e,p] -[ worker_mortality_rate + (4^(p - POISONING)) ]-> DW
}


measure n_worker = #W[e, p for e in [0,ENERGY] and p in [0,POISONING]];


system init = Q[0]<1>;

