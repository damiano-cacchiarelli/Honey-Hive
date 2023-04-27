

/* -------------------------------------------------------------------------- */
/*                               CONST & AGENTS                               */
/* -------------------------------------------------------------------------- */

/*Bees*/
const ENERGY = 10;                          /* The energy available to a bee. A bee with 0 energy cannot perform activities */
const NECTAR_BEE_STORAGE = 10;              /* A bee need 10 flowes to fill its nectar storage */
const POISONING = 10;                       /* The poisoning level of a bee */

/*Flowers*/
const SPECIES = 2;                          /* The number of flower species in the simulation */
const NECTAR_AVAILABLE = 2;                 /* 1 if the flower has nectar available; 0 if not available */


/* --------------------------------- Agents --------------------------------- */

species Q of [0, ENERGY];                                                         /* Queen */

species WR of [0, ENERGY]*[0, POISONING];                                         /* Worker in Rest state */
species WF of [0, ENERGY]*[0, NECTAR_BEE_STORAGE]*[0, POISONING];                 /* Worker in Find state */
species WS of [0, ENERGY]*[0, NECTAR_BEE_STORAGE]*[0, POISONING];                 /* Worker in Store state */
species WP of [0, ENERGY]*[0, POISONING];                                         /* Worker in Produce state */

species H;                                                                        /* Honey Storage */
species N;                                                                        /* Nectar Storage */

species F of [0, SPECIES]*[0, NECTAR_AVAILABLE];                                  /* Flowers */

species DQ;                                                                       /* Death Queen */
species DW;                                                                       /* Death Worker */

/* --------------------------------- Consts --------------------------------- */

/*Bee*/
const worker_life = 20;                     /* On average, a bee lives about 20 days */
const queen_life = 700;                     /* On average, a queen lives about 2 years */

/*Environment*/
const ideal_humidity = 5;                   /* A positive natural number between 0 and 9*/
const ideal_temperature = 31;
const delta_temperature = 8;

/*Hive*/
const max_storage = 1000000;                /* The amount of honey that can be stored */
const max_bee_population = 100;             /* The maximum number of bees in the hive */


/* ------------------------------- Multipliers ------------------------------ */

const time_multiplier = 6;


/* ---------------------------------- Rate ---------------------------------- */

const worker_birth_rate = 0.9 ;
const worker_mortality_rate = 1/(worker_life * time_multiplier) ;
const queen_mortality_rate = 1/(queen_life * time_multiplier);

const eat_rate = 0.9 ;
const queen_metabolism = 0.15 ;
const worker_metabolism = 0.15 ;

const find_activity_rate = 1;
const store_activity_rate = 1;
const produce_activity_rate = 1;
/*
const find_activity_rate = 1.5;
const store_activity_rate = 0.7;
const produce_activity_rate = 2;
*/
const bee_change_state_rate = 0.9 ;
const bee_store_nectar = 0.9;
const bee_produce_honey = 1;

const flower_pruduce_nectar_rate = 0.25 ;


/* --------------------------------- Params --------------------------------- */

param temperature = 31 ;
param humidity = 5;
param pesticide_exposure_rate = 0.0 ;

/* ---------------------------------- Math constants --------------------------------- */

/*
{ID: WF_1} Workers population function:

    1/4^(#workers - critical_workers_population/3)

critical_workers_population:
    The minimum number of bee that ... TODO

*/
const critical_workers_population = 5;      

/*
{ID: HF_1} Humidity function:

    1\(humidity - ideal_humidity)^2humidity_impact;

humidity_impact:
    Defines how fast the function for humidity goes up;
    integer; Ranges between 0 and 10 -> [0, 10];

*/
const humidity_impact = 1;

/*
{ID: EF_1} Energy function: 

    0.1 + 0.8/(1+(x/critical_energy)^2energy_impcat)

energy_impcat:
    Defines how fast the function for energy goes down;
    Integer; Ranges between 1 and 10 -> [1, 10];

critical_energy:
    Describe when a bee's energy becomes critical;
    Defines the point at which the function decreases;
    Integer; Ranges between 1 and 5 -> [1, 5];

*/
const energy_impcat = 2;
const critical_energy = 3;


/* -------------------------------------------------------------------------- */
/*                                   LABELS                                   */
/* -------------------------------------------------------------------------- */

label flowers = { F[s, n for s in [0,SPECIES] and n in [0, NECTAR_AVAILABLE]] }
label flowers_nectar_available = { F[s, 1 for s in [0,SPECIES]] }
label workers_in_rest = { WR[e, p for e in [1,ENERGY] and p in [0,POISONING]] }
label workers_in_find = { WF[e, n, p for e in [1,ENERGY] and n in [0,NECTAR_BEE_STORAGE] and p in [0,POISONING]] }
label workers_in_store = { WS[e, n, p for e in [1,ENERGY] and n in [0,NECTAR_BEE_STORAGE] and p in [0,POISONING]] }
label workers_in_produce = { WP[e, p for e in [1,ENERGY] and p in [0,POISONING]] }
label workers = {
    WR[e, p for e in [1,ENERGY] and p in [0,POISONING]],
    WF[e, n, p for e in [1,ENERGY] and n in [0,NECTAR_BEE_STORAGE] and p in [0,POISONING]],
    WS[e, n, p for e in [1,ENERGY] and n in [0,NECTAR_BEE_STORAGE] and p in [0,POISONING]],
    WP[e, p for e in [1,ENERGY] and p in [0,POISONING]]
  
}

label used_storage = {N, H}

/* -------------------------------------------------------------------------- */
/*                                    RULES                                   */
/* -------------------------------------------------------------------------- */

/* ---------------------------------- Queen --------------------------------- */

/*
Queen Eat HONEY:
    Increase ENERGY;
    Descrease HONEY Storage (H);

Base rates: 
    eat_rate;

Impacts:
    Residual ENERGY;
*/
rule queen_eat_honey for e in [0, ENERGY-2]{
    Q[e] | H<1> -[ eat_rate * (1-1.5^(e-ENERGY))]-> Q[e+2]
}

/* 
Queen generate a Worker (WR):
    Drecrease ENERGY;
    Increase number of Worker;

Base rates: 
    worker_birth_rate;

Impacts: 
    Residual ENERGY (Low ENERGY decrease worker_birth_rate);
    Number of Worker (High number of Worker decrease worker_birth_rate);
*/
rule queen_generate_worker for e in [1, ENERGY] {
    Q[e] -[ worker_birth_rate * 1.7^(e-ENERGY) * (1-#workers/max_bee_population) ]-> Q[e] | WR[ENERGY-1, 0]
}

/*
Queen consume ENERGY:
    Drecrease ENERGY;

Base rates:
    queen_metabolism;
*/
rule queen_consume_energy for e in [1, ENERGY]{
    Q[e] -[queen_metabolism]-> Q[e-1]
}


/* 
Queen dies:

Base rates: 
    queen_mortality_rate;

Impacts: 
    Number of Worker {WF_1} (Low number of Worker increase queen_mortality_rate);

*/
rule queen_dies for e in [0, ENERGY]{
    Q[e] -[ queen_mortality_rate + 1/4^(#workers - critical_workers_population/3)]-> DQ
}

/* ----------------------------- Worker in REST ----------------------------- */

/*
Worker from REST (WR) go to FIND (WF) state:
    Bee change state;
    Decrease bee ENERGY;

Base rates:
    bee_change_state_rate;

Impacts:
    Residual ENERGY (Low ENERGY decrease bee_change_state_rate);
    Residual HONEY (H) and NECTAR (N) in the hive;
*/
rule worker_rest_to_find for e in [1, ENERGY] and p in [0, POISONING] {
    WR[e,p] -[bee_change_state_rate * 1.5^(e-ENERGY)]-> WF[e,0,p]
}

/*
Worker (WR) eat from HONEY storage (H):
    Increase ENERGY;
    Decrise HONEY storage;

BaseRate:
    eat_rate;

Impacts:
    Residual ENERGY (Low ENERGY increase eat_rate);
*/
rule worker_eat for e in [0, ENERGY-2] and p in [0, POISONING] {
    WR[e,p] | H<1> -[eat_rate*(1-1.5^(e-ENERGY))]-> WR[e+2,p]
}

/*
Worker in rest (WR) dies:
    Add new entity in Death Worker (DW) specie;

Base rates:
    worker_mortality_rate

Impacts:
    POISONING level (High level of POISONING increase worker_mortality_rate)

*/
rule worker_rest_dies for e in [0, ENERGY] and p in [0, POISONING] {
    WR[e,p] -[ worker_mortality_rate + (4^(p - POISONING)) ]-> DW
}



/* --------------------------------- Worker in FIND --------------------------------- */

/*
Worker from FIND (WF) go to STORE (WS) state:
    Bee change state;

Base rates:
    bee_change_state_rate;

Impacts:
    Residual ENERGY (Low ENERGY increase bee_change_state_rate);
    Level of NECTAR_BEE_STORAGE (Low NECTAR_BEE_STORAGE decrease bee_change_state_rate);
    Level of POISONING (High POISONING decrease bee_change_state_rate);
*/
rule worker_find_to_store for e in [0, ENERGY] and n in [0, NECTAR_BEE_STORAGE] and p in [0, POISONING] {
    WF[e,n,p] -[bee_change_state_rate * ((1-1.3^(e-ENERGY))+(1.2^(n-NECTAR_BEE_STORAGE))/5) * (1-(p/2*POISONING))]-> WS[e,n,p]
}

/*
Worker (WF) meets a Flower (F) with NECTAR_AVAILABLE equal to 1 :
    Increase NECTAR_BEE_STORAGE;
    Set NECTAR_AVAILABLE to 0;

Base rates:

Impacts:
    Residual ENERGY (Low ENERGY decrease bee_meets_flower_rate);
    Residual Flowers with NECTAR_AVAILABLE;
*/
rule worker_meets_flower for e in [1, ENERGY] and n in [0, NECTAR_BEE_STORAGE-1] and p in [0, POISONING] and s in [0, SPECIES]{
    WF[e,n,p] | F[s,1] -[(#flowers_nectar_available/#flowers) * 1.5^(e/ENERGY)]-> WF[e,n+1,p] | F[s,0]
}

/*
Worker (WF) is infected with pesticide:
    Increase POISONING;

Base rates:
    pesticide_exposure_rate;

Impacts:

*/
rule worker_exposed_pesticide for e in [0, ENERGY] and n in [0, NECTAR_BEE_STORAGE] and p in [0, POISONING-1] {
    WF[e,n,p] -[pesticide_exposure_rate]-> WF[e,n,p+1]
}

/*
Worker (WF) consume ENERGY.
    Decrease ENERGY;

Base rates:
    worker_metabolism;

Impacts:
    find_activity_rate;
*/

rule worker_find_consume_energy for e in [1, ENERGY] and n in [0, NECTAR_BEE_STORAGE] and p in [0, POISONING]{
    WF[e,n,p] -[worker_metabolism * find_activity_rate]-> WF[e-1,n,p]
}

/*
Worker in find (WF) dies:
    Add new entity in Death Worker (DW) specie;

Base rates:
    worker_mortality_rate

Impacts:
    POISONING level (High level of POISONING increase worker_mortality_rate)

*/
rule worker_find_dies for e in [0, ENERGY] and n in [0, NECTAR_BEE_STORAGE] and p in [0, POISONING]{
    WF[e,n,p] -[ worker_mortality_rate + (4^(p - POISONING)) ]-> DW
}


/* ----------------------------- Worker in STORE ---------------------------- */

/*
Worker from STORE (WS) without NECTAR_BEE_STORAGE go to PRODUCE (WP) state:
    Bee change state;

Base rates:
    bee_change_state_rate;

Impacts:
    Residual ENERGY (Low ENERGY decrease bee_change_state_rate);
*/
rule worker_store_to_produce for e in [1, ENERGY] and p in [0, POISONING] {
    WS[e,0,p] -[bee_change_state_rate * (1-1.3^(e-ENERGY))]-> WP[e,p]
}

/*        TODO


Worker from STORE (WS) without ENERGY go to REST (WR) state:
    Bee change state;
    NECTAR_BEE_STORAGE lost;

Base rates:
    bee_change_state_rate;


rule worker_store_to_rest for n in [0, NECTAR_BEE_STORAGE] and p in [0, POISONING] {
    WS[0,n,p] -[bee_change_state_rate]-> WR[0,p]
}*/

/* 
Worker (WS) store NECTAR (N):
    Decrease bee ENERGY;
    Increase NECTAR storage (N);

Base rates:
    bee_store_nectar;

*/
rule worker_store_nectar for e in [1, ENERGY] and n in [1, NECTAR_BEE_STORAGE] and p in [0, POISONING] {
    WS[e,n,p] -[bee_store_nectar]-> WS[e,0,p] | N<n*2>
}

/*
Worker (WS) consume ENERGY.
    Decrease ENERGY;

Base rates:
    worker_metabolism;

Impacts:
    store_activity_rate;
*/

rule worker_store_consume_energy for e in [1, ENERGY] and n in [0, NECTAR_BEE_STORAGE] and p in [0, POISONING]{
    WS[e,n,p] -[worker_metabolism * store_activity_rate]-> WS[e-1,n,p]
}

/*
Worker in store (WS) dies:
    Add new entity in Death Worker (DW) specie;

Base rates:
    worker_mortality_rate

Impacts:
    POISONING level (High level of POISONING increase worker_mortality_rate)

*/
rule worker_store_dies for e in [0, ENERGY] and n in [0, NECTAR_BEE_STORAGE] and p in [0, POISONING]{
    WS[e,n,p] -[ worker_mortality_rate + (4^(p - POISONING)) ]-> DW
}


/* ---------------------------- Worker in PRODUCE --------------------------- */

/*
Worker from PRODUCE (WP) go to REST (WR) state:
    Bee change state;

Base rates:
    bee_change_state_rate;

Impacts:
    Level of NECTAR (N) (Low NECTAR increase bee_change_state_rate);
    Residual ENERGY {EF_1} (Low ENERGY increase bee_change_state_rate);
TODO
*/
    /*WP[e,p] -[bee_change_state_rate * ((0.8/(1+(e/critical_energy)^(2*energy_impcat))) + 0.1) * (1-(#N/(max_storage-#H)))/4]-> WR[e,p]*/

rule worker_produce_to_rest for e in [1, ENERGY] and p in [0, POISONING] {
    WP[e,p] -[bee_change_state_rate * ((0.8/(1+(e/critical_energy)^(2*energy_impcat))) + 0.1) ]-> WR[e,p]
}

/* 
Worker (WP) produce HONEY (H):
    Decrease NECTAR storage (N);
    Increase HONEY storage (H);

Base rates:
    bee_produce_honey;

Impacts:
    Residual ENERGY (Low ENERGY decrease bee_produce_honey);
    Humidity impacts bee_produce_honey {HF_1};
*/
rule worker_produce_honey for e in [1, ENERGY] and p in [0, POISONING] {
    WP[e,p] | N<4> -[bee_produce_honey * (1/(1+(humidity-ideal_humidity)^(2*humidity_impact))) * 1.3^(e-ENERGY)]-> WP[e,p] | H<1>
}

/*
Worker (WP) consume ENERGY.
    Decrease ENERGY;

Base rates:
    worker_metabolism;

Impacts:
    produce_activity_rate;
*/

rule worker_produce_consume_energy for e in [1, ENERGY] and p in [0, POISONING]{
    WP[e,p] -[worker_metabolism * produce_activity_rate]-> WP[e-1,p]
}

/*
Worker in produce (WP) dies:
    Add new entity in Death Worker (DW) specie;

Base rates:
    worker_mortality_rate

Impacts:
    POISONING level (High level of POISONING increase worker_mortality_rate)

*/
rule worker_produce_dies_energy for e in [0, ENERGY] and p in [0, POISONING] {
    WP[e,p] -[ worker_mortality_rate + (4^(p - POISONING)) ]-> DW
}

/* --------------------------------- Flower --------------------------------- */

/*
Flower (F) produce NECTAR:
    NECTAR become AVAILABLE;

Base rates:
    flower_pruduce_nectar_rate

Impacts:

*/
rule flower_produce_nectar for s in [0, SPECIES]{
    F[s,0] -[flower_pruduce_nectar_rate]-> F[s,1]
}


/* -------------------------------------------------------------------------- */
/*                            MEASURES & PREDICATE                            */
/* -------------------------------------------------------------------------- */

measure n_worker = #workers;
measure workers_in_rest = #workers_in_rest;
measure workers_in_find = #workers_in_find;
measure workers_in_store = #workers_in_store;
measure workers_in_produce = #workers_in_produce;
measure honey_available = #H;
measure nectar_available = #N;
measure flower_with_nectar = #flowers_nectar_available;
measure workers_death = #DW;
measure queen_death = #DQ;
measure workers_no_energy = #WR[0, p for p in [0,POISONING]]+#WF[0, n, p for n in [0,NECTAR_BEE_STORAGE] and p in [0,POISONING]]+#WS[0, n, p for n in [0,NECTAR_BEE_STORAGE] and p in [0,POISONING]]+#WP[0, p for p in [0,POISONING]];

/* 
predicate honey_decrise = (#HS < 50);
predicate workers = ( #W[i for i in [0,STATES], j for j in [0,ENERGY], z for z in [0,POISONING]]>0);
*/

/*TODO reproduction rate*/
/* -------------------------------------------------------------------------- */
/*                                   SYSTEM                                   */
/* -------------------------------------------------------------------------- */
system initial = Q[ENERGY-1]<1> | WR[ENERGY-1, 0]<20> | H<1> | N<1> | F[0,1]<50> | F[1,1]<50>;