#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void generate_primes(int limit, int **primes, int *prime_count);
int count_le(int prime, int *primes, int prime_count);

int main(int argc, char *argv[])
{
	int value;
	int *primes;
	int prime_count;
	generate_primes(1000000, &primes, &prime_count);

	while (scanf("%d", &value) != -1) {
		printf("%d\n", count_le(value, primes, prime_count));
	}

	free(primes);
	return 0;
}

void generate_primes(int limit, int **primes_out, int *prime_count_out)
{
	int i;
	int *primes, *remains, prime_count, prime_length;
	char *marks;
	int marks_length;

	prime_length = 1024;
	primes = calloc(prime_length, sizeof(int));
	remains = calloc(prime_length, sizeof(int));

	primes[0] = 2;
	primes[1] = 3;
	prime_count = 2;

	marks_length = 1024;
	marks = calloc(marks_length, sizeof(char));

	for (i=0; primes[prime_count-1]<limit; i++) {
		int j;
		int extend_length;
		extend_length = primes[i+1] * primes[i+1] - primes[i] * primes[i];

		/* prepare marks buffer */
		if (marks_length < extend_length) {
			while (marks_length < extend_length) {
				marks_length *= 2;
			}
			free(marks);
			marks = calloc(marks_length, sizeof(char));
		} else {
			memset(marks, 0, marks_length);
		}

		/* mark prime multiple */
		for (j = 0; j <= i; j++) {
			int pos;
			for (pos = remains[j]; pos < extend_length; pos += primes[j]) {
				marks[pos] = 1;
			}
			remains[j] = pos - extend_length;
		}

		/* append new primes */
		for (j = 0; j < extend_length; j++) {
			if (!marks[j]) {
				int prime;
				prime = primes[i] * primes[i] + j;
				if (prime_count == prime_length) {
					prime_length *= 2;
					primes = realloc(primes, prime_length * sizeof(int));
					remains = realloc(remains, prime_length * sizeof(int));
				}
				primes[prime_count] = prime;
				remains[prime_count] = 0;
				prime_count++;
			}
		}
	}

	free(remains);
	free(marks);

	*primes_out = primes;
	*prime_count_out = prime_count;
}

int count_le(int value, int *primes, int prime_count)
{
	int left, right;
	left = 0;
	right = prime_count;
	while (left < right) {
		int middle = (left + right) / 2;
		if (value < primes[middle]) {
			right = middle;
		} else {
			left = middle + 1;
		}
	}
	return left;
}