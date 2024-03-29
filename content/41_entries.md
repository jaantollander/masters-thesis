\clearpage

## Entries and issues

Format | Observed entry identifier
-|-
Correct | `wget.11317854`
Correct | `11317854:17627127:r01c01`
Missing job ID | `:17627127:r01c01`
Malformed | `wget`
Malformed | `wget.`
Malformed | `11317854`
Malformed | `11317854:`
Malformed | `113178544`
Malformed | `11317854:17627127`
Malformed | `11317854:17627127:`
Malformed | `11317854:17627127:r01c01.bullx`
Malformed | `:17627127:r01c01.bullx`
Malformed | `:1317854:17627127:r01c01`

: \label{tab:jobid-examples}
Examples of various observed entry identifiers.
The examples show correct entry identifiers, identifiers with missing job IDs, and various malformed identifiers.

We found that some of the observed entry identifiers did not conform to the format on the settings described in Section \ref{entry-identifier-format}.
Table \ref{tab:jobid-examples} demonstrates correct entry identifiers, an entry identifier with missing job ID, and different malformed entry identifiers we observed.

The first issue is missing job ID values.
Slurm sets a Slurm job ID for all non-system users running jobs on compute nodes, and the identifier should include it.
However, we found many entries from non-system users on compute nodes without a job ID.
Due to these issues, data from the same job might scatter into multiple time series without reliable indicators making it impossible to provide reliable statistics for specific jobs.
The issue might be related to problems fetching the environment variable's value.
This issue occurred in both MDSs and OSSs on Puhti.

The second, more severe issue is that there were malformed entry identifiers.
The issue is likely related to the lack of thread safety in the functions that produce the entry identifier strings in the Lustre Jobstats code.
A recent bug report mentioned broken entry identifiers [@jobid-atomic], which looked similar to our problems.
Consequently, we cannot reliably parse information from these entry identifiers, and we had to discard them, which resulted in data loss.
This issue occurred only in OSSs on Puhti.
We obtained feasible values for correct entry identifiers, but we are still determining if the integrity of the counter values is affected by this issue.
Next, we look at Figures \ref{fig:entry-ids-mdt} and \ref{fig:entry-ids-ost}, which show the number of entries per Lustre target and identifier format for system and non-system users in a sample of 74 Jobstats outputs taken every 2-minutes from 2022-03-04.

\definecolor{non-system-user}{rgb}{0.1216,0.4667,0.7059}
\definecolor{system-user}{rgb}{1.0,0.498,0.0549}

\clearpage

![
The number of entries for each of the four MDTs during a sample of Jobstats outputs taken every 2 minutes during an interval on 2022-03-04.
Each subplot shows a different identifier format; line color indicates \textcolor{non-system-user}{non-system users} and \textcolor{system-user}{system users}; and each line shows a different MDT for a given user type.
We can see many missing job IDs compared to intact ones for non-system users, many entries for system users, and an unbalanced load between MDTs.
The first subplot shows the number of correct entries for login and utility nodes, and the second subplot shows them for compute nodes.
The third subplot shows the number of missing job IDs on compute nodes, which is substantial compared to the correct identifiers in the second subplot.
There are no malformed entries on MDTs.
\label{fig:entry-ids-mdt}
](figures/entry_ids_mdt.svg)

\clearpage

![
The number of entries for each of the 24 OSTs during a sample of Jobstats outputs taken every 2 minutes during an interval on 2022-03-04.
Each subplot shows a different identifier format; line color indicates \textcolor{non-system-user}{non-system users} and \textcolor{system-user}{system users}; and each line shows a different OST for a given user type.
We can see many missing job IDs compared to intact ones for non-system users, many entries for system users, systematic generation of malformed entry identifiers, and a balanced load between OSTs.
The first subplot shows the number of correct entries for login and utility nodes, and the second subplot shows them for compute nodes.
The third subplot shows the number of missing job IDs on compute nodes, which is substantial compared to the correct identifiers in the second subplot.
The fourth subplot shows the number of malformed identifiers for all nodes.
We can see that Jobstats on Puhti systematically produce missing job IDs and malformed identifiers.
Furthermore, there is a large burst of malformed identifiers from 12:06 to 12:26, indicating that in some conditions, Jobstats produces large amounts of malformed identifiers.
\label{fig:entry-ids-ost}
](figures/entry_ids_ost.svg)

\clearpage

We can see that only two of the four MDTs handle almost all of the metadata operations.
Of the two active MDTs, the first one handles more operations than the second one, but their magnitudes correlate.
The load across MDTs is unbalanced because MDTs are assigned based on the top-level directory.
Each MDT is assigned to a different storage area, such as Home, Projappl, or Scratch, covered in Section \ref{puhti-cluster-at-csc}, and the load is unbalanced because the usage of these storage areas varies.
On the contrary, the load across OSTs is balanced because the files are assigned OSTs equally with a round-robin policy unless the user explicitly overwrites this policy.

We see that the number of entry identifiers with missing job IDs is substantial compared to the number of correct identifiers for non-system users.
We also observe that Jobstats systemically generates malformed identifiers on the OSSs, and in certain conditions, maybe due to heavy load on the OSS, it can create many of them.

Entries from non-system users are the most valuable ones for analysis.
However, we see that system users generate many entries.
By inspecting the data, we found that only two system users, root and job control, generate these entries in Puhti.
Furthermore, most of these entries contain little valuable information; for example, many have a single `statfs` operation.
Also, entries from system users usually did not have a job ID as their processes do not run via Slurm, although sometimes they do have a job ID.

Regarding data accumulation, each entry corresponds to one row in the database.
Therefore, reducing the number of entries reduces storage size and speeds up queries and the analysis.
We should discard or aggregate statistics of system users to reduce the accumulation of unnecessary data.
In general, correct entry identifiers would reduce unnecessary data accumulation.
