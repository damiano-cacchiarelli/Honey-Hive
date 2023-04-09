

/* -------------------------------------------------------------------------- */
/*                               CONST & AGENTS                               */
/* -------------------------------------------------------------------------- */

const ENERGY = 10;
const STATES = 3;                           /* Worker has 4 STATES: Rest (0), Find (1), Store (2), Produce (3); */
const MAX_STORAGE = 1000;
const MAX_BEE_POPULATION = 10000;
const SPECIES = 1;
const WATER_CONCENTRATION = 90;
const NECTAR_AVAILABLE = 1;
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

species HS; /* Honey Storage */ /*TODO*/
species HT; /* Max Honey Storage */ /*TODO*/

species DB; /* Death Bee */ /*TODO*/

/* ---------------------------------- Rate ---------------------------------- */

const bee_birth_rate = 0.5 ;
const bee_mortality_rate = 0.2 ;
const queen_mortality_rate = 0.01 ;

const queen_metabolism = 0.25 ;
const bee_metabolism = 0.40 ;

const bee_change_state_rate = 0.9;

const flower_pruduce_nectar_rate = 0.25 ;

const temperature = 1 ; /*TODO*/
const nectar_availability_rate = 0.5 ; /*TODO*/
const pesticide_exposure = 0.01 ;

/* -------------------------------------------------------------------------- */
/*                                   LABELS                                   */
/* -------------------------------------------------------------------------- */

label flowers_nectar_available = { F[i, j, 1 for i in [0,SPECIES] and j in [0,WATER_CONCENTRATION]]}


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
    Q[0] -[ 1 ]-> DB
}

/* --------------------------------- Worker in FIND --------------------------------- */

/*
Worker from REST (WR) go to FIND (WF) state:
    Bee change state;
    Decrease bee ENERGY;
    (*) Decrease Honey Storage (H);

Base rates:
    bee_change_state_rate;

Impacts:
    Residual ENERGY (Low ENERGY decrease bee_change_state_rate);
    (*) Residual HONEY (H) in the hive;
*/
rule worker_rest_to_find for i in [4, ENERGY] and j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE] {
    WR[i,j,z] -[bee_change_state_rate * (1-((ENERGY-i)/ENERGY))]-> WF[i-1,j,z]
}

/*
Worker (WF) meets a Flower (F) with NECTAR_AVAILABLE equal to 1 :
    Decrease bee ENERGY;
    Increase NECTAR_BEE_STORAGE;
    Set NECTAR_AVAILABLE to 0;

Base rates:

Impacts:
    Residual ENERGY (Low ENERGY decrease bee_meets_flower_rate);
    Residual Flowers with NECTAR_AVAILABLE;
*/
rule worker_meets_flower for i in [1, ENERGY-1] and j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE] and a in [0, SPECIES] and b in [0, WATER_CONCENTRATION]{
    WF[i,j,z] | F[a,b,1] -[%flowers_nectar_available * (1-((ENERGY-i)/ENERGY))]-> WF[i,j+1,z] | F[a,b,0]
}

/* ----------------------------- Worker in STORE ---------------------------- */

/*
Worker from FIND (WF) go to STORE (WS) state:
    Bee change state;
    Increase bee DISEASE;

Base rates:
    bee_change_state_rate;

Impacts:
    Residual ENERGY (Low ENERGY increase bee_change_state_rate);
    Level of NECTAR_BEE_STORAGE (Low NECTAR_BEE_STORAGE decrease bee_change_state_rate);
*/
rule worker_find_to_store for i in [1, ENERGY] and j in [0, NECTAR_BEE_STORAGE] and z in [0, DISEASE] {
    WF[i,j,z] -[bee_change_state_rate * ((ENERGY-i)/ENERGY) * (1-((NECTAR_BEE_STORAGE-j)/NECTAR_BEE_STORAGE))]-> WS[i,j,z]
}

/* ---------------------------- Worker in PRODUCE --------------------------- */

/*
Worker from STORE (WS) go to PRODUCE (WP) state:
    Bee change state;

Base rates:
    bee_change_state_rate;

Impacts:

*/
rule worker_rest_to_find for i in [1, ENERGY] and z in [0, DISEASE] {
    WS[i,0,z] -[bee_change_state_rate]-> WP[i,0,z]
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
rule worker_rest_to_find for i in [1, ENERGY] and z in [0, DISEASE] {
    WP[i,0,z] -[bee_change_state_rate]-> WR[i,0,z]
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

measure n_worker = #W[i, j, z for i in [0,STATES] and j in [0,ENERGY] and z in [0,DISEASE]];
measure honey_available = #H;

/* 

predicate honey_decrise = (#HS < 50);
predicate workers = ( #W[i for i in [0,STATES], j for j in [0,ENERGY], z for z in [0,DISEASE]]>0);

*/


/* -------------------------------------------------------------------------- */
/*                                   SYSTEM                                   */
/* -------------------------------------------------------------------------- */
system initial = Q[ENERGY/2]<1> | W[0,5,0]<0> | H<50>;