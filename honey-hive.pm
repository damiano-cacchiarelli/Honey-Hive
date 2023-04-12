

/* -------------------------------------------------------------------------- */
/*                               CONST & AGENTS                               */
/* -------------------------------------------------------------------------- */

const ENERGY = 10;
const STATES = 3;                           /* Worker has 4 STATES: Rest (0), Find (1), Store (2), Produce (3); */
const MAX_STORAGE = 10000;
const MAX_BEE_POPULATION = 10000;
const SPECIES = 2;
const WATER_CONCENTRATION = 90;
const NECTAR_AVAILABLE = 2;
const DISEASE = 10;
const NECTAR_BEE_STORAGE = 10;              /* A bee need 10 flowes to fill its nectar storage*/

/* --------------------------------- Agents --------------------------------- */
species Q of [0, ENERGY];                                                         /* Queen */
species WR of [0, ENERGY]*[0, NECTAR_BEE_STORAGE]*[0, DISEASE];                   /* Worker in Rest state */
species WF of [0, ENERGY]*[0, NECTAR_BEE_STORAGE]*[0, DISEASE];                   /* Worker in Find state */
species WS of [0, ENERGY]*[0, NECTAR_BEE_STORAGE]*[0, DISEASE];                   /* Worker in Store state */
species WP of [0, ENERGY]*[0, NECTAR_BEE_STORAGE]*[0, DISEASE];                   /* Worker in Produce state */
species H;                                                                        /* Honey Storage */
species N;                                                                        /* Nectar Storage */
species F of [0, SPECIES]*[0, WATER_CONCENTRATION]*[0, NECTAR_AVAILABLE];         /* Flowers */

species DW; /* Death Worker */
species DQ; /* Death Worker */


/* ---------------------------------- Rate ---------------------------------- */

const bee_birth_rate = 0.5 ;
const bee_mortality_rate = 0.2 ;
const queen_mortality_rate = 0.01 ;

const queen_metabolism = 0.15 ;
const bee_metabolism = 0.25 ;
const eat_rate = 1;

const bee_change_state_rate = 0.9;

const flower_pruduce_nectar_rate = 0.25 ;

const temperature = 1 ; /*TODO*/
const nectar_availability_rate = 0.5 ; /*TODO*/
const pesticide_exposure = 0.01 ;

/* -------------------------------------------------------------------------- */
/*                                   LABELS                                   */
/* -------------------------------------------------------------------------- */

label flowers_nectar_available = { F[i, j, 1 for i in [0,SPECIES] and j in [0,WATER_CONCENTRATION]] }
label workers_in_rest = { WR[i, j, z for i in [1,ENERGY] and j in [0,NECTAR_BEE_STORAGE] and z in [0,DISEASE]] }
label workers_in_find = { WF[i, j, z for i in [1,ENERGY] and j in [0,NECTAR_BEE_STORAGE] and z in [0,DISEASE]] }
label workers_in_store = { WS[i, j, z for i in [1,ENERGY] and j in [0,NECTAR_BEE_STORAGE] and z in [0,DISEASE]] }
label workers_in_produce = { WP[i, j, z for i in [1,ENERGY] and j in [0,NECTAR_BEE_STORAGE] and z in [0,DISEASE]] }


/* -------------------------------------------------------------------------- */
/*                                    RULES                                   */
/* -------------------------------------------------------------------------- */

/* ---------------------------------- Queen --------------------------------- */

/*
Queen Eat food:
    Increase ENERGY;
    Descrease Honey Storage (H);

Base rates: 
    queen_metabolism;

Impacts:
    Residual ENERGY;
*/
rule queen_eat_food for i in [1, ENERGY-1]{
    Q[i] | H<4*0.5> -[ 0.5 ]-> Q[i+1]
}

/* 
Queen generate a Worker (W):
    Drecrease ENERGY;
    Increase number of Worker;

Base rates: 
    bee_birth_rate;

Impacts: 
    Residual ENERGY (Low ENERGY decrease bee_birth_rate);
    (*) Number of Worker (High number of Worker decrease bee_birth_rate);
*/
rule queen_generate_worker for i in [1, ENERGY] {
    Q[i] -[ 0.5 ]-> Q[i-1] | WR[5, 0, 0]
}

/*
Queen dies:
    The residual ENERGY is 0;
*/
rule queen_dies {
    Q[0] -[ 1 ]-> DQ
}

/* --------------------------------- Workers -------------------------------- */
/*
Worker dies:
    The residual ENERGY is 0;
*/
rule worker_rest_dies for j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE]{
    WR[0,j,z] -[ 1 ]-> DW
}
rule worker_find_dies for j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE]{
    WF[0,j,z] -[ 1 ]-> DW
}
rule worker_store_dies for j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE]{
    WS[0,j,z] -[ 1 ]-> DW
}
rule worker_produce_dies for j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE]{
    WP[0,j,z] -[ 1 ]-> DW
}


/* --------------------------------- Worker in FIND --------------------------------- */

/*
Worker from REST (WR) go to FIND (WF) state:
    Bee change state;
    Decrease bee ENERGY;

Base rates:
    bee_change_state_rate;

Impacts:
    Residual ENERGY (Low ENERGY decrease bee_change_state_rate);
    (*) Residual HONEY (H) in the hive;
*/
rule worker_rest_to_find for i in [1, ENERGY] and j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE] {
    WR[i,j,z] -[bee_change_state_rate * (i/ENERGY)]-> WF[i-1,j,z]
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
rule worker_meets_flower for i in [1, ENERGY-1] and j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE] and a in [0, SPECIES] and b in [0, WATER_CONCENTRATION]{
    WF[i,j,z] | F[a,b,1] -[%flowers_nectar_available * (i/ENERGY)]-> WF[i,j+1,z] | F[a,b,0]
}

/*
Worker (WF) is infected with pesticide:
    Increase DISEASE;

Base rates:
    pesticide_exposure;

Impacts:

*/
rule worker_exposed_pesticide for i in [1, ENERGY] and j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE-1] {
    WF[i,j,z] -[pesticide_exposure]-> WF[i,j,z+1]
}

/* ----------------------------- Worker in STORE ---------------------------- */

/*
Worker from FIND (WF) go to STORE (WS) state:
    Bee change state;

Base rates:
    bee_change_state_rate;

Impacts:
    Residual ENERGY (Low ENERGY increase bee_change_state_rate);
    Level of NECTAR_BEE_STORAGE (Low NECTAR_BEE_STORAGE decrease bee_change_state_rate);
*/
rule worker_find_to_store for i in [1, ENERGY] and j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE] {
    WF[i,j,z] -[bee_change_state_rate * ((ENERGY-i)/ENERGY) * (j/NECTAR_BEE_STORAGE)]-> WS[i,j,z]
}

/* 
Worker (WS) store Nectar (N):
    Decrease bee ENERGY;
    Increase Nectar storage (N);  

TODO */
rule worker_store_nectar for i in [1, ENERGY] and j in [1, NECTAR_BEE_STORAGE] and z in [0, DISEASE] {
    WS[i,j,z] -[1]-> WS[i-1,0,z] | N<j>
}

/* ---------------------------- Worker in PRODUCE --------------------------- */

/*
Worker from STORE (WS) go to PRODUCE (WP) state:
    Bee change state;
    Decrease bee ENERGY;

Base rates:
    bee_change_state_rate;

Impacts:

*/
rule worker_store_to_produce for i in [1, ENERGY] and z in [0, DISEASE] {
    WS[i,0,z] -[bee_change_state_rate]-> WP[i-1,0,z]
}

/* 
Worker (WP) produce Honey (H):
    Decrease bee ENERGY;
    Decrease Nectar storage (N);
    Increase Honey storage (H);

TODO :
    Use H[] in order to store decimal numbers??
    Humidity impacts honey production??
*/
rule worker_produce_honey for i in [1, ENERGY] and j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE] {
    WP[i,j,z] | N<4> -[1]-> WP[i-1,j,z] | H<1>
}


/* ----------------------------- Worker in REST ----------------------------- */

/*
Worker from PRODUCE (WP) go to REST (WR) state:
    Bee change state;

Base rates:
    bee_change_state_rate;

Impacts:
    Level of NECTAR (N) (Low NECTAR increase bee_change_state_rate);
    Residual ENERGY (Low ENERGY increase bee_change_state_rate);
*/
rule worker_produce_to_rest for i in [1, ENERGY] and j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE] {
    WP[i,j,z] -[bee_change_state_rate]-> WR[i,j,z]
}

/*
Worker (WR) eat from Honey storage (H):
    Increase ENERGY;
    Decrise Honey storage;
BaseRate:
    eat_rate;

Impacts:
    Residual ENERGY (Low ENERGY decrease eat_rate);
*/
rule worker_eat for i in [1, ENERGY-1] and j in [1, NECTAR_BEE_STORAGE] and z in [0, DISEASE] {
    WR[i,j,z]<5> | H -[(1-(i/ENERGY))*eat_rate]-> WR[i+1,j,z]<5>
} 


/* --------------------------------- Flower --------------------------------- */

/*
Flower (F) produce NECTAR:
    NECTAR become AVAILABLE;

Base rates:
    flower_pruduce_nectar_rate

Impacts:
    Wather condition;
*/
rule flower_produce_nectar for i in [0, SPECIES] and j in [0, WATER_CONCENTRATION]{
    F[i,j,0] -[flower_pruduce_nectar_rate]-> F[i,j,1]
}


/* -------------------------------------------------------------------------- */
/*                            MEASURES & PREDICATE                            */
/* -------------------------------------------------------------------------- */

measure n_worker = (#workers_in_find + #workers_in_find + #workers_in_store + #workers_in_produce);
measure honey_available = #H;
measure nectar_available = #N;
measure flower_with_nectar = #flowers_nectar_available;
measure flower_without_nectar = #F[i, j, 0 for i in [0,SPECIES] and j in [0,WATER_CONCENTRATION]];
measure worker_death = #DW;

/* 
predicate honey_decrise = (#HS < 50);
predicate workers = ( #W[i for i in [0,STATES], j for j in [0,ENERGY], z for z in [0,DISEASE]]>0);
*/


/* -------------------------------------------------------------------------- */
/*                                   SYSTEM                                   */
/* -------------------------------------------------------------------------- */
system initial = Q[ENERGY/2]<1> | H<50> | N<1000> | F[0,70,1]<500> | F[1,80,1]<500>;