Since the advent of civilization, humans have had a need to store, process and distribute information such as accounting of food reserves and depts, tracking harvesting cycles and weather and writing down laws. This had lead to the emergence of systems like writing, numbers and arithmetic.

Our desire to process information and perform calculation in automated way instead of manually as tedious, error prone human process has lead to the invention and development of various machines from mechanical calculators to the modern digital computers. Information storage has evolved from clay tablets and papyrus to the modern digital storage.

We call the automated calculation as computation and the machines that perform them as computers.

The computers can solve numerical problems that would be impractical or impossible to calculate manually. Such problem include weather prediction, simulation, theorem proving, computer aided design, and many others.

---

A commonly used abstract, mathematical model of computation is the Turing machine. It consists of a finite set of symbols, a tape memory consisting of these symbols, and finite table of rules of how to transform symbols on the tape.

Turing machine is used as a theoretical tool for classifying computational problems by their difficulty. As a simple computer, the Turing machine is also useful tool for thinking about the essential components of a computer.

Turing machine has important properties such as universality, which means that a Turing machine can simulate any other Turing machine by enconding its symbols, rules, and initial tape by using its own symbols to its own tape and using rules designed to interpret the embeded Turing machine.

- embeded Turing machine though as a program
- universality leads to programmability
- ability to store programs on tape
- distinction between software vs hardware in Turing machine

---

Modern computer systems are complex and contain many parts.

Characteristics of modern computer hardware.

- General and special purpose *processors* which manipulate data by performing operations on them. Modern processor employ multiple levels of parallelism to perform multiple operations simultaneously to increase throughput.

- Various *memory* units for storing data. Modern computers employ multiple memory units ordered by their proximity to the processor to increase throughtput. They are organized hierarchically from fast, volatile, working memory close to the processor to slow, nonvolatile, storage memory far from the processor.

- *Buses* for internal data transportation between hardware components.

- *Input/Output* for interacting with the computer system.

Examples

- ALU, registers, Central Processing Unit (CPU)
- Random Access Memory (RAM)
- specialized processors, Graphics Processing Unit (GPU)
- keyboard, mouse, display

Characteristics of modern computer software.

- *Operating System* is a special program which is responsible for the communication between application programs and the hardware.

- *Device Drivers* are programs that enable the operating system to communicate with external devices.

- *Application Programs* are programs executed by the user.

Examples

- Linux operating system, system vs user space
- drivers, graphics
- application programs: browser, terminal emulator, simulation program

---

We can increase the scale of a computer system by connecting multiple computers together to form a *computer network*.

- individual connected computer system is called a node or host
- nodes are identified by unique addresses
- topology of the network means the arrangement of nodes is a defining characteristic of computer network
- communication between systems, direct communication vs communication protocol
- tightly vs loosely coupled (connected) (centralized vs distributed, speed vs robustness)

Examples

- cloud computing, internet
- grid computing
- computer cluster

