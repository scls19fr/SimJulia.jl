using Base.Test
using SimJulia

function waitup(process::Process, signals)
	occured_signals = wait(process, signals)
	println("At $(now(process)), $occured_signals was fired that activated $process")
end

function queueup(process::Process, signals)
	occured_signals = queue(process, signals)
	println("At $(now(process)), $occured_signals was fired that activated $process")
end

function send_signals(process::Process, signal1::Signal, signal2::Signal, signal3::Signal, signal4::Signal)
	hold(process, 2.0)
	fire(signal1)
	hold(process, 8.0)
	fire(signal2)
	hold(process, 5.0)
	fire(signal1)
	fire(signal2)
	fire(signal3)
	fire(signal4)
	hold(process, 5.0)
	fire(signal4)
end

sim = Simulation(uint(16))
signal1 = Signal("Signal-1")
signal2 = Signal("Signal-2")
signal3 = Signal("Signal-3")
signal4 = Signal("Signal-4")
signals = Set{Signal}()
add!(signals, signal3)
add!(signals, signal4)
signaller = Process(sim,"Signaller")
activate(signaller, 0.0, send_signals, signal1, signal2, signal3, signal4)
w0 = Process(sim, "W-0")
activate(w0, 0.0, waitup, signal1)
w1 = Process(sim, "W-1")
activate(w1, 0.0, waitup, signal2)
w2 = Process(sim, "W-2")
activate(w2, 0.0, waitup, signals)
q1 = Process(sim, "Q-1")
activate(q1, 0.0, queueup, signals)
q2 = Process(sim, "Q-2")
activate(q2, 0.0, queueup, signals)
run(sim, 50.0)
