Lustre servers and targets have a finite capacity limit (may vary across time due to system conditions)

Finite capacity is distributed across actors, that is, values of specific metadata, e.g user, job)

During high total load, if there is more heavy I/O, there is less light I/O.

Uncorrelated actors are less likely to perform heavy I/O at the same time independently than correlated actors.
Actors can be correlated in many ways, e.g. two users communicating, users use the same software, two jobs belong to same user, etc

Thus it is likely that some actors perform much heavier I/O than others.
(Fat tails)
