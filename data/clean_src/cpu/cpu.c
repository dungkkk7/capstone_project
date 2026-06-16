#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_N 100
#define AGING_INTERVAL 4

typedef struct Process {
    int pid;
    int arrival;
    int burst;
    int remaining;
    int executed;
    int basePriority;
    int deadline;
    int firstStart;
    int finish;
} Process;

typedef struct Segment {
    int pid;
    int start;
    int end;
} Segment;

typedef struct SegmentList {
    Segment *data;
    int size;
    int capacity;
} SegmentList;

int maxInt(int a, int b) {
    return a > b ? a : b;
}

void initSegments(SegmentList *list) {
    list->size = 0;
    list->capacity = 64;
    list->data = (Segment *)malloc(sizeof(Segment) * list->capacity);
}

void addSegment(SegmentList *list, int pid, int start, int end) {
    if (end <= start) return;

    if (list->size > 0) {
        Segment *last = &list->data[list->size - 1];

        if (last->pid == pid && last->end == start) {
            last->end = end;
            return;
        }
    }

    if (list->size >= list->capacity) {
        list->capacity *= 2;
        list->data = (Segment *)realloc(
            list->data,
            sizeof(Segment) * list->capacity
        );
    }

    list->data[list->size].pid = pid;
    list->data[list->size].start = start;
    list->data[list->size].end = end;
    list->size++;
}

void generateProcesses(Process *p, int n) {
    for (int i = 0; i < n; i++) {
        int arrival = (i * i + 3 * i) % (n + 4);
        int burst = ((i + 2) * 7) % 9 + 2;
        int priority = ((i * 3 + n) % 5) + 1;
        int deadline = arrival + burst + ((i * 4 + n) % 7) + 3;

        p[i].pid = i + 1;
        p[i].arrival = arrival;
        p[i].burst = burst;
        p[i].remaining = burst;
        p[i].executed = 0;
        p[i].basePriority = priority;
        p[i].deadline = deadline;
        p[i].firstStart = -1;
        p[i].finish = -1;
    }
}

int effectivePriority(Process *p, int currentTime) {
    int waiting = currentTime - p->arrival - p->executed;
    int eff = p->basePriority - waiting / AGING_INTERVAL;

    if (eff < 0) eff = 0;

    return eff;
}

int slackTime(Process *p, int currentTime) {
    return p->deadline - currentTime - p->remaining;
}

int isBetter(Process *a, Process *b, int currentTime) {
    int ea = effectivePriority(a, currentTime);
    int eb = effectivePriority(b, currentTime);

    if (ea != eb) return ea < eb;

    int sa = slackTime(a, currentTime);
    int sb = slackTime(b, currentTime);

    if (sa != sb) return sa < sb;
    if (a->remaining != b->remaining) return a->remaining < b->remaining;
    if (a->arrival != b->arrival) return a->arrival < b->arrival;

    return a->pid < b->pid;
}

int chooseProcess(Process *p, int n, int currentTime) {
    int best = -1;

    for (int i = 0; i < n; i++) {
        if (p[i].arrival <= currentTime && p[i].remaining > 0) {
            if (best == -1 || isBetter(&p[i], &p[best], currentTime)) {
                best = i;
            }
        }
    }

    return best;
}

int nextArrival(Process *p, int n, int currentTime) {
    int best = 1000000000;

    for (int i = 0; i < n; i++) {
        if (
            p[i].remaining > 0 &&
            p[i].arrival > currentTime &&
            p[i].arrival < best
        ) {
            best = p[i].arrival;
        }
    }

    return best;
}

void simulate(Process *p, int n, SegmentList *segments) {
    int done = 0;
    int time = 0;

    while (done < n) {
        int chosen = chooseProcess(p, n, time);

        if (chosen == -1) {
            int jump = nextArrival(p, n, time);
            addSegment(segments, 0, time, jump);
            time = jump;
            continue;
        }

        if (p[chosen].firstStart == -1) {
            p[chosen].firstStart = time;
        }

        addSegment(segments, p[chosen].pid, time, time + 1);

        p[chosen].remaining--;
        p[chosen].executed++;
        time++;

        if (p[chosen].remaining == 0) {
            p[chosen].finish = time;
            done++;
        }
    }
}

void printProcessTable(Process *p, int n) {
    printf("Generated processes:\n");
    printf("PID  Arr  Burst  Priority  Deadline\n");

    for (int i = 0; i < n; i++) {
        printf(
            "P%-3d %-4d %-6d %-9d %d\n",
            p[i].pid,
            p[i].arrival,
            p[i].burst,
            p[i].basePriority,
            p[i].deadline
        );
    }
}

void printGanttChart(SegmentList *segments) {
    printf("\nGantt chart:\n");

    for (int i = 0; i < segments->size; i++) {
        Segment s = segments->data[i];

        if (s.pid == 0) {
            printf("[%d-%d: IDLE]", s.start, s.end);
        } else {
            printf("[%d-%d: P%d]", s.start, s.end, s.pid);
        }

        if (i + 1 < segments->size) {
            printf(" -> ");
        }
    }

    printf("\n");
}

void printResultTable(Process *p, int n) {
    double totalWaiting = 0.0;
    double totalTurnaround = 0.0;
    double totalResponse = 0.0;
    int totalLate = 0;

    printf("\nResult table:\n");
    printf("PID  Start  Finish  Waiting  Turnaround  Response  Late\n");

    for (int i = 0; i < n; i++) {
        int turnaround = p[i].finish - p[i].arrival;
        int waiting = turnaround - p[i].burst;
        int response = p[i].firstStart - p[i].arrival;
        int late = maxInt(0, p[i].finish - p[i].deadline);

        totalWaiting += waiting;
        totalTurnaround += turnaround;
        totalResponse += response;
        totalLate += late;

        printf(
            "P%-3d %-6d %-7d %-8d %-11d %-9d %d\n",
            p[i].pid,
            p[i].firstStart,
            p[i].finish,
            waiting,
            turnaround,
            response,
            late
        );
    }

    printf("\nSummary:\n");
    printf("Average waiting time: %.2f\n", totalWaiting / n);
    printf("Average turnaround time: %.2f\n", totalTurnaround / n);
    printf("Average response time: %.2f\n", totalResponse / n);
    printf("Total late penalty: %d\n", totalLate);
}

void printWorstProcess(Process *p, int n) {
    int worst = 0;

    for (int i = 1; i < n; i++) {
        int lateA = maxInt(0, p[i].finish - p[i].deadline);
        int lateB = maxInt(0, p[worst].finish - p[worst].deadline);

        if (lateA > lateB) {
            worst = i;
        } else if (lateA == lateB) {
            int waitA = p[i].finish - p[i].arrival - p[i].burst;
            int waitB = p[worst].finish - p[worst].arrival - p[worst].burst;

            if (waitA > waitB) {
                worst = i;
            }
        }
    }

    printf(
        "Worst process: P%d, finish = %d, deadline = %d, late = %d\n",
        p[worst].pid,
        p[worst].finish,
        p[worst].deadline,
        maxInt(0, p[worst].finish - p[worst].deadline)
    );
}

int main() {
    int n;

    if (scanf("%d", &n) != 1) {
        printf("Invalid input\n");
        return 0;
    }

    if (n < 1 || n > MAX_N) {
        printf("N must be in range [1, %d]\n", MAX_N);
        return 0;
    }

    Process *processes = (Process *)malloc(sizeof(Process) * n);
    SegmentList segments;

    initSegments(&segments);
    generateProcesses(processes, n);

    printf("CPU Scheduling Simulation\n");
    printf("Input N = %d\n\n", n);
    printf(
        "Rule: lower effective priority runs first; "
        "aging improves priority every %d waiting units.\n\n",
        AGING_INTERVAL
    );

    printProcessTable(processes, n);

    simulate(processes, n, &segments);

    printGanttChart(&segments);
    printResultTable(processes, n);
    printWorstProcess(processes, n);

    free(segments.data);
    free(processes);

    return 0;
}