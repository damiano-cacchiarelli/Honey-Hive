

/* -------------------------------------------------------------------------- */
/*                               CONST & AGENTS                               */
/* -------------------------------------------------------------------------- */

const ENERGY = 10;
const STATES = 3;                                           /* Worker has 4 STATES: Rest (0), Find (1), Store (2), Produce (3); */
const MAX_STORAGE = 1000;
const MAX_BEE_POPULATION = 10000;
const SPECIES = 1;
const WATER_CONCENTRATION = 100;
const DISEASE = 10;

/* --------------------------------- Agents --------------------------------- */
species Q of [0, ENERGY];                                   /* Queen */
species W of [0, STATES]*[0, ENERGY]*[0, DISEASE];          /* Worker */
species H of [0, MAX_STORAGE];                              /* Honey Storage */ /*TODO*/
species F of [0, SPECIES]*[0, WATER_CONCENTRATION];         /* Flowers */

species HS; /* Honey Storage */ /*TODO*/
species HT; /* Max Honey Storage */ /*TODO*/

species DB; /* Death Bee */ /*TODO*/

/* ---------------------------------- Rate ---------------------------------- */

const bee_birth_rate = 0.5 ;
const bee_mortality_rate = 0.2 ;
const queen_mortality_rate = 0.01 ;

const queen_metabolism = 0.25 ;
const bee_metabolism = 0.40 ;

const temperature = 1 ; /*TODO*/
const nectar_availability_rate = 0.5 ; /*TODO*/
const pesticide_exposure = 0.01 ;

/* -------------------------------------------------------------------------- */
/*                                   LABELS                                   */
/* -------------------------------------------------------------------------- */



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
rule queen_eat_food for i in [0, ENERGY-2]{
    Q[i] | HS -[ 0.5 ]-> Q[i+2] | HT
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
    Q[i] -[ 0.5 ]-> Q[i-1] | W[0, 5, 0]
}

/*
Queen dies:
    The residual ENERGY is 0;
*/
rule queen_dies {
    Q[0] -[ 1 ]-> DB
}


/* -------------------------------------------------------------------------- */
/*                            MEASURES & PREDICATE                            */
/* -------------------------------------------------------------------------- */

measure n_worker = #W[i, j, z for i in [0,STATES] and j in [0,ENERGY] and z in [0,DISEASE]];
measure honey_available = #HS;

predicate honey_decrise = (#HS < 50);
/*predicate workers = ( #W[i for i in [0,STATES], j for j in [0,ENERGY], z for z in [0,DISEASE]]>0);*/


/* -------------------------------------------------------------------------- */
/*                                   SYSTEM                                   */
/* -------------------------------------------------------------------------- */
system initial = Q[ENERGY/2]<1> | W[0,5,0]<0> | HS<50> | HT<100>;