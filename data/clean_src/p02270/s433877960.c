#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define TRUE (1)
#define FALSE (0)

/* DataType */
typedef uint32_t Weight_t;
typedef uint8_t Bool;
typedef struct tagConfigure_t Configure_t;
typedef struct tagSolver_t Solver_t;

struct tagConfigure_t {
	uint32_t truckMaxCount;
	uint32_t loadageMaxCount;
};

struct tagSolver_t {
	Weight_t* loadage;
	Weight_t  maxLoadingCapacity;
	Configure_t config;
};

/* Public Methods */
void     Solver_Initialize(Solver_t* self);
void     Solver_Free(Solver_t* self);
void     Solver_GetProblemConfigure(Solver_t* self);
void     Solver_Solve(Solver_t* self);
Weight_t Solver_GetMaxLoadingCapacity(Solver_t* self);

/* Private Methods */
static Weight_t Solver_Sum(Weight_t* weights, uint32_t count);
static Bool     Solver_CanLoaded(Weight_t* weights, uint32_t maxLoadingCapacity,
																 uint32_t loadageMaxCount, uint32_t truckMaxCount);

int main(void)
{
	Solver_t solver;

	Solver_Initialize(&solver);

	Solver_GetProblemConfigure(&solver);

	Solver_Solve(&solver);

	printf("%d\n", Solver_GetMaxLoadingCapacity(&solver));

	Solver_Free(&solver);
}

void Solver_Initialize(Solver_t* self)
{
	self->loadage                  = NULL;
	self->maxLoadingCapacity       = 0;
	(self->config).truckMaxCount   = 0;
	(self->config).loadageMaxCount = 0;
}

void Solver_GetProblemConfigure(Solver_t* self)
{
	char* numStr;
	char readLine[256];
	char buf[256];

	if (scanf("%255[^\n]%*[^\n]", readLine) != 1) {
		exit(0);
	}

	numStr = strtok(readLine, " ");
	(self->config).loadageMaxCount = atoi(numStr);
	
	numStr = strtok(NULL, " ");
	(self->config).truckMaxCount   = atoi(numStr);

	self->loadage = (Weight_t*)malloc(((self->config).loadageMaxCount)*sizeof(Weight_t));

	for (uint32_t i = 0;i < (self->config).loadageMaxCount;i++) {
		char*    weightStr;
		Weight_t weight;

		scanf("%*c", buf);

		if (scanf("%255[^\n]%*[^\n]", readLine) != 1) {
			exit(0);
		}

		weightStr = strtok(readLine, " ");
		weight    = atoi(weightStr);

		self->loadage[i] = weight;
	}
}

void Solver_Solve(Solver_t* self)
{
	Weight_t upperBound, lowerBound, middle;

	upperBound = Solver_Sum(self->loadage, (self->config).loadageMaxCount);
	lowerBound = Solver_Sum(self->loadage, (self->config).loadageMaxCount) / (self->config).truckMaxCount;

	while (upperBound > lowerBound) {
		middle = (upperBound + lowerBound) / 2;
		if (Solver_CanLoaded(self->loadage, middle, (self->config).loadageMaxCount,
												 (self->config).truckMaxCount)) {
			upperBound = middle;
		} else {
			lowerBound = middle + 1;
		}
	}

	self->maxLoadingCapacity = lowerBound;
}

void Solver_Free(Solver_t* self)
{
	free(self->loadage);
}

Weight_t Solver_GetMaxLoadingCapacity(Solver_t* self)
{
	return self->maxLoadingCapacity;
}

static Weight_t Solver_Sum(Weight_t* weights, uint32_t count)
{
	Weight_t sum = 0;

	for (uint32_t i=0;i < count;i++) {
		sum += weights[i];
	}

	return sum;
}

static Bool Solver_CanLoaded(Weight_t* weights, uint32_t maxLoadingCapacity, 
														 uint32_t loadageMaxCount, uint32_t truckMaxCount)
{
	Weight_t weightsPerTruck = 0;
	uint32_t numOfTrucks = 0;

	for (uint32_t i = 0;i < loadageMaxCount;i++) {
		weightsPerTruck += weights[i];

		if (weightsPerTruck > maxLoadingCapacity) {
			numOfTrucks++;
			weightsPerTruck = weights[i];
		}

		if (numOfTrucks == truckMaxCount || weightsPerTruck > maxLoadingCapacity) {
			return FALSE;
		}
	}

	return TRUE;
}

