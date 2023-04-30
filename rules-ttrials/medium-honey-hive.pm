/* -------------------------------------------------------------------------- */
/*                               CONST & AGENTS                               */
/* -------------------------------------------------------------------------- */

/*Bees*/
const ENERGY = 10;                          /* The energy available to a bee. A bee with 0 energy cannot perform activities */
const POISONING = 10;                       /* The poisoning level of a bee */

/*Flowers*/
const SPECIES = 3;                          /* The number of flower species in the simulation */
const NECTAR_AVAILABLE = 2;                 /* 1 if the flower has nectar available; 0 if not available */

/* --------------------------------- Agents --------------------------------- */

species Q of [0, ENERGY];                               /* Queen */

species WB of [0, ENERGY]*[0, POISONING];               /* Worker Bee, perform activities in the hive */
species FB of [0, ENERGY]*[0, POISONING];               /* Forager Bee, seeks nectar outside the hive */

species H;                                              /* Honey Storage */
species N;                                              /* Nectar Storage */

species F of [0, SPECIES]*[0, NECTAR_AVAILABLE];        /* Flowers */

species DQ;                                             /* Death Queen */
species DW;                                             /* Death Worker */
species DF;                                             /* Death Forager */

/*Debug*/
species N_F;   /*Nectar used for food */
species N_H;   /*Nectar used for Honey*/
species N_QF;  /*Nectar used for Queen food */

species BB;    /*Born Bees*/

/* --------------------------------- Consts --------------------------------- */

/*Bee*/


/*Environment*/

const ideal_temperature = 31;                   /* A positive natural number between 10 and 40*/           
const delta_temperature = 8;                    /* A positive natural number between 0 and 9*/

/*Hive*/            
const food_storage = 1000;                      /* The amount of nectar that can be stored */
const max_bee_population = 100;                 /* The maximum number of bees in the hive */

/* ---------------------------------- Rates ---------------------------------- */

const queen_mortality_rate = 0.0005 ;

const eat_rate = 0.90 ;
const queen_metabolism = 0.25 ;
const bee_birth_rate = 0.90 ;

const worker_metabolism = 0.30 ;
const worker_mortality_rate = 0.35 ;

const forager_metabolism = 0.30 ;
const forager_mortality_rate = 0.35 ;

const bee_store_nectar = 0.9;

const flower_pruduce_nectar_rate = 0.1 ;
const rainfall_rate = 1;


/* --------------------------------- Params --------------------------------- */

param temperature = 31 ;
param humidity = 5;
param pesticide_exposure_rate = 0.0 ;


/* ---------------------------------- Math functions --------------------------------- */

/*
{ID: WF_1} Workers population function:

    1/4^(#workers - critical_workers_population/3)

#workers:
    The total workers in the hive (#WB + #FB);

critical_workers_population:
    The minimum number of bee that ... TODO

*/
const critical_workers_population = 10;

/*
{ID: HF_1} Humidity function:

    1/(humidity - ideal_humidity)^2humidity_impact;

ideal_humidity:
    TODO
    A positive natural number between 0 and 9

humidity_impact:
    Defines how fast the function for humidity goes up;
    integer; Ranges between 0 and 10 -> [0, 10];

*/
const ideal_humidity = 5;
const humidity_impact = 1;
const humidity_rate = 1/(((humidity - ideal_humidity)^2*humidity_impact)+1);

/* -------------------------------------------------------------------------- */
/*                                   LABELS                                   */
/* -------------------------------------------------------------------------- */

/*Flowers*/
label flowers = { F[s, n for s in [0,SPECIES] and n in [0, NECTAR_AVAILABLE]] }
label flowers_nectar_available = { F[s, 1 for s in [0,SPECIES]] }

/*Bees*/
label workers = { WB[e, p for e in [1,ENERGY] and p in [0,POISONING]] }
label foragers = { FB[e, p for e in [1,ENERGY] and p in [0,POISONING]] }
label worker_bees = {
    WB[e, p for e in [1,ENERGY] and p in [0,POISONING]],
    FB[e, p for e in [1,ENERGY] and p in [0,POISONING]]
}

/*Hive*/            
label used_storage = {N, H}

/* -------------------------------------------------------------------------- */
/*                                    RULES                                   */
/* -------------------------------------------------------------------------- */

/* ---------------------------------- Queen --------------------------------- */

/*
>> QUEEN EATS <<

Results:
    Increase ENERGY;
    Descrease NECTAR Storage (N);

Base rates: 
    eat_rate;

Impacts:
    Residual ENERGY (Low ENERGY increase eat_rate);
*/
rule queen_eats for e in [0, ENERGY-2]{
    Q[e] | N<3> -[ eat_rate * (1-1.5^(e-ENERGY))]-> Q[e+2] | N_QF<3>
}

/*
>> QUEEN   generate WORKER <<

Results:
    Drecrease Queen ENERGY;
    Increase number of Worker (WB);

Base rates: 
    bee_birth_rate;

Impacts: 
    Food availbility (Low Food decrease bee_birth_rate);
    Number of Worker (High number of Worker decrease bee_birth_rate);
*/
rule queen_generate_worker for e in [1, ENERGY] {
    Q[e] -[ bee_birth_rate * (e/ENERGY) * ((#used_storage+1)/food_storage)]-> Q[e] | WB[ENERGY-1, 0]<2> | FB[ENERGY-1, 0]<2> | BB<2>
}

/*
>> QUEEN consume ENERGY <<

Results:
    Drecrease Queen (Q) ENERGY;

Base rates:
    queen_metabolism;
*/
rule queen_consume_energy for e in [1, ENERGY]{
    Q[e] -[queen_metabolism]-> Q[e-1]
}

/* 
>> QUEEN DIES <<

Results:
    Increase Death Queen (DQ);

Base rates: 
    queen_mortality_rate;

Impacts: 
    Number of Workers {WF_1} (Low number of Workers increase queen_mortality_rate);

*/
rule queen_dies for e in [0, ENERGY]{
    Q[e] -[ queen_mortality_rate + 1/4^(#worker_bees - critical_workers_population/2) ]-> DQ
}


/* ------------------------------- Worker Bee ------------------------------- */

/*
>> WORKER EATS <<

Results:
    Increase Worker (WB) ENERGY;
    Decrise NECTAR storage (N);

BaseRate:
    eat_rate;

Impacts:
    Residual ENERGY (Low ENERGY increase eat_rate);
*/
rule worker_eat for e in [0, ENERGY-1] and p in [0, POISONING] {
    WB[e,p] | N<1> -[eat_rate * (1 - e/ENERGY)]-> WB[e+1,p] | N_F<1>
}

/*
>> WORKER consume ENERGY <<

Results:
    Decrease Worker (WB) ENERGY;

Base rates:
    worker_metabolism;
*/
rule worker_consume_energy for e in [1, ENERGY] and p in [0, POISONING]{
    WB[e,p] -[worker_metabolism]-> WB[e-1,p]
}

/*
>> WORKER DIES <<

Results:
    Add new entity in Death Worker (DW) species;

Base rates:
    worker_mortality_rate

Impacts:
    Residual ENERGY (Low ENERGY increase worker_mortality_rate);
    POISONING level (High level of POISONING increase worker_mortality_rate);
    Temperature impact (TODO);
*/
rule worker_dies for e in [0, ENERGY] and p in [0, POISONING] {
    WB[e,p] -[ worker_mortality_rate * (1 - e/ENERGY) + 4^(p - POISONING)]-> DW
}


/*
>> WORKER becomes FORAGER <<

Results:
    Add new entity in Forager bee (WB) species;

*/
rule worker_become_forager for e in [0, ENERGY] and p in [0, POISONING-1] {
    WB[e,p] -[(1.0 - #N/food_storage) * (#FB/worker_bees - 0.5)]-> FB[e,p]
}

/* ------------------------------- Forager Bee ------------------------------ */

/*
>> FORAGER EATS <<

Results:
    Increase Forager (WB) ENERGY;
    Decrise NECTAR storage (N);

BaseRate:
    eat_rate;

Impacts:
    Residual ENERGY (Low ENERGY increase eat_rate);
*/
rule forager_eat for e in [0, ENERGY-1] and p in [0, POISONING] {
    FB[e,p] | N<1> -[eat_rate * (1 - e/ENERGY)]-> FB[e+1,p] | N_F<1>
}

/*
>> FORAGER consume ENERGY <<

Results:
    Decrease Forager (FB) ENERGY;

Base rates:
    forager_metabolism;
*/
rule forager_consume_energy for e in [1, ENERGY] and p in [0, POISONING]{
    FB[e,p] -[forager_metabolism]-> FB[e-1,p]
}

/*
>> FORAGER DIES <<

Results:
    Add new entity in Death Forager (DF) species;

Base rates:
    forager_mortality_rate

Impacts:
    Residual ENERGY (Low ENERGY increase forager_mortality_rate);
    POISONING level (High level of POISONING increase forager_mortality_rate);
    Temperature impact (TODO);
*/
rule forager_dies for e in [0, ENERGY] and p in [0, POISONING] {
    FB[e,p] -[ forager_mortality_rate * (1 - e/ENERGY) + 4^(p - POISONING)]-> DF
}

/*
>> FORAGER meets FLOWER <<

Results:
    Increase NECTAR storage (N);
    Set FLOWER (F) NECTAR_AVAILABLE to 0;

Base rates:
    bee_store_nectar;

Impacts:
    Food availbility (Low Food increase bee_store_nectar);
    Residual Flowers with NECTAR_AVAILABLE (Low Flowers decrease bee_store_nectar);
*/
rule forager_meets_flower for e in [1, ENERGY] and p in [0, POISONING] and s in [0, SPECIES]{
    FB[e,p] | F[s,1] -[bee_store_nectar * (1- #used_storage/food_storage)*(#flowers_nectar_available/#flowers)]-> FB[e,p] | F[s,0] | N<2>
}

/*
>> TODO
Worker (WF) is infected with pesticide:
    Increase POISONING;

Base rates:
    pesticide_exposure_rate;
*//*
rule worker_exposed_pesticide for e in [0, ENERGY] and p in [0, POISONING-1] {
    FB[e,p] -[pesticide_exposure_rate]-> FB[e,p+1]
}*/

/*
>> FORAGER becomes WORKER <<

Results:
    Add new entity in Worker bee (WB) species;

*//*
rule forager_become_worker for e in [0, ENERGY] and p in [0, POISONING-1] {
    FB[e,p] -[(1.0 - #N/food_storage) * #FB/]-> WB[e,p]
}*/

/* --------------------------------- Flower --------------------------------- */

/*
Flower (F) produce NECTAR:
    NECTAR become AVAILABLE;

Base rates:
    flower_pruduce_nectar_rate

Impacts:
    Param rainfall_rate (Low rainfall decrease flower_pruduce_nectar_rate);
*/
rule flower_produce_nectar for s in [0, SPECIES]{
    F[s,0] -[flower_pruduce_nectar_rate * rainfall_rate]-> F[s,1]
}


/* -------------------------------------------------------------------------- */
/*                            MEASURES & PREDICATE                            */
/* -------------------------------------------------------------------------- */

measure n_bees = #worker_bees;
measure workers = #workers;
measure forages = #foragers;

measure honey_available = #H;
measure nectar_available = #N;
measure flower_with_nectar = #flowers_nectar_available;
measure workers_death = #DW + #DF;
measure queen_death = #DQ;

measure nectar_food = #N_F;
measure nectar_honey = #N_H;
measure nectar_queen_food = #N_QF;

measure born_bee = #BB;

predicate colony_survived = (#Q[e for e in [0, ENERGY]] > 0);
/* 
predicate honey_decrise = (#HS < 50);
predicate workers = ( #W[i for i in [0,STATES], j for j in [0,ENERGY], z for z in [0,POISONING]]>0);
*/

/* -------------------------------------------------------------------------- */
/*                                   SYSTEM                                   */
/* -------------------------------------------------------------------------- */
system init = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<10> | FB[ENERGY-1, 0]<10> | H<0> | N<20> | F[0,1]<500> | F[1,1]<500>;

system init1 = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<10> | FB[ENERGY-1, 0]<10> | H<0> | N<20> | F[0,1]<500> | F[1,1]<500>;
system init2 = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<20> | H<0> | N<20> | F[0,1]<5> | F[1,1]<5>;



system new_hive = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<20>  | H<0> | N<20>             | F[0,1]<500> | F[1,1]<500>;
system old_hive = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<500> | H<0> | N<food_storage/2> | F[0,1]<500> | F[1,1]<500>;

system new_hive_desert = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<20>  | H<0> | N<20>             | F[0,1]<10>;
system old_hive_desert = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<500> | H<0> | N<food_storage/2> | F[0,1]<10>;

system new_hive_frozen_river = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<20>  | H<0> | N<20>             | F[0,1]<300> | F[1,1]<300>;
system old_hive_frozen_river = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<500> | H<0> | N<food_storage/2> | F[0,1]<300> | F[1,1]<300>;

system new_hive_flower_forest = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<20>  | H<0> | N<20>             | F[0,1]<350> | F[1,1]<350> | F[2,1]<350>;
system old_hive_flower_forest = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<500> | H<0> | N<food_storage/2> | F[0,1]<350> | F[1,1]<350> | F[2,1]<350>;


/* -------------------------------------------------------------------------- */
/*                                TODO & NOTES                                */
/* -------------------------------------------------------------------------- */

/* 
NOTES:

------------------------------------ - -----------------------------------
Worker (WS) store NECTAR (N):
    Decrease bee ENERGY;
    Increase NECTAR storage (N);

Base rates:
    bee_store_nectar;


rule worker_store_nectar for e in [1, ENERGY] and p in [0, POISONING] {
    WB[e,p] -[bee_store_nectar * (1- #used_storage/food_storage)]-> WB[e,p] | N<1>
}
------------------------------------ - -----------------------------------

*/

/*
TODO: 
    Possible simulation: Pesticidi?? Temperature intermedie (caldo-normale e normale-freddo)??
*/