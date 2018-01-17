/*
  Rokas Palionis_IFF-5/8
*/


import org.jcsp.lang.*;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.util.Scanner;

public class PalionisRokas_L3a {

	static final int thread_amount = 5;
	static final int array_limit = 30;
	static final int array_element_limit = 5;
	
	//Pašalina visus duomenis
//	static final String filename = "PalionisRokas_L3a.dat_1.txt";
	//Nepašalina jokių duomenų
//	static final String filename = "PalionisRokas_L3a.dat_2.txt";
	//Pašalina dalį duomenų
	static final String filename = "PalionisRokas_L3a.dat_3.txt";
	
	public static void main(String[] args) throws IOException {

		//Kuriami kanalai
		Any2OneChannel AddChannel = Channel.any2one();
		Any2OneChannel RemoveChannel = Channel.any2one();
		One2AnyChannel[] Proccess00Channel = Channel.one2anyArray(2 + 1);
		One2AnyChannel ControllerChannel = Channel.one2any();
		
		//Lygiagrečių procesų masyvas
		Parallel ParallelThreads = new Parallel();
		
		//Kuriami įdėjimo procesai
		CSProcess[] AddProcesses = new CSProcess[thread_amount];
		for (int i = 0; i < thread_amount; i++)
			AddProcesses[i] = new ProcessAdd(i, Proccess00Channel[0].in(), AddChannel.out());
		ParallelThreads.addProcess(AddProcesses);
		//Kuriami šalinimo procesai
		CSProcess[] RemoveProcesses = new CSProcess[thread_amount];
		for (int i = 0; i < thread_amount; i++)
			RemoveProcesses[i] = new ProcessRemove(i, Proccess00Channel[1].in(), RemoveChannel.out(), ControllerChannel.in());
		ParallelThreads.addProcess(RemoveProcesses);
		//Kuriamas procesas00
		ParallelThreads.addProcess(new Process00(Proccess00Channel));
		//Kuriamas valdytojo procesas
		ParallelThreads.addProcess(new Controller(thread_amount, AddChannel, RemoveChannel, Proccess00Channel[2].out(), ControllerChannel));
		//Paleidžiami procesai
		ParallelThreads.run();
		
		System.out.println("Programa baigė darbą.");
	}
		
};

//Bendra struktūra P
class PStruct {
	String name;
	int wins;
	double points;
	
	public PStruct() {
		this.name = "";
		this.wins = 0;
		this.points = 0.0;
	}
	
}

//Bendra struktūra V
class VStruct {
	String sorting_field;
	int amount;
	
	public VStruct() {
		this.sorting_field = "";
		this.amount = 0;
	}
	
}

//Papildoma klasė skirta int tipui, kuri leidžia funkcijų viduje keisti kintamojo reikšmes
class mutableInt {
	private int value;
	
	public mutableInt(int value) {
		this.value = value;
	}
	
	public int getValue() {
		return this.value;
	}
	
	public void setValue(int value) {
		this.value = value;
	}
	
}

class Process00 implements CSProcess {
	//Masyvas sudarytas iš struktūros PStruct ir reikšmėms sudėti papildomas masyvo identifikatorius
	private PStruct [] P1;
	private PStruct [] P2;
	private PStruct [] P3;
	private PStruct [] P4;
	private PStruct [] P5;
	private mutableInt p1_amount;
	private mutableInt p2_amount;
	private mutableInt p3_amount;
	private mutableInt p4_amount;
	private mutableInt p5_amount;

	//Masyvas sudarytas iš struktūros VStruct ir reikšmėms sudėti papildomas masyvo identifikatorius
	private VStruct [] V1;
	private VStruct [] V2;
	private VStruct [] V3;
	private VStruct [] V4;
	private VStruct [] V5;
	private mutableInt v1_amount;
	private mutableInt v2_amount;
	private mutableInt v3_amount;
	private mutableInt v4_amount;
	private mutableInt v5_amount;
	
	//Bendras masyvas sudarytas iš struktūros VStruct ir reikšmėms sudėti papildomas masyvo identifikatorius
	private VStruct [] B;
	private mutableInt b_amount;
	
	//Proceso kanalas
	private One2AnyChannel[] Proccess00Channel;
	
	public Process00(One2AnyChannel[] proccess00Channel2) {
		P1 = new PStruct[PalionisRokas_L3a.array_element_limit];
		P2 = new PStruct[PalionisRokas_L3a.array_element_limit];
		P3 = new PStruct[PalionisRokas_L3a.array_element_limit];
		P4 = new PStruct[PalionisRokas_L3a.array_element_limit];
		P5 = new PStruct[PalionisRokas_L3a.array_element_limit];
		p1_amount = new mutableInt(0);
		p2_amount = new mutableInt(0);
		p3_amount = new mutableInt(0);
		p4_amount = new mutableInt(0);
		p5_amount = new mutableInt(0);
		
		V1 = new VStruct[PalionisRokas_L3a.array_element_limit];
		V2 = new VStruct[PalionisRokas_L3a.array_element_limit];
		V3 = new VStruct[PalionisRokas_L3a.array_element_limit];
		V4 = new VStruct[PalionisRokas_L3a.array_element_limit];
		V5 = new VStruct[PalionisRokas_L3a.array_element_limit];
		v1_amount = new mutableInt(0);
		v2_amount = new mutableInt(0);
		v3_amount = new mutableInt(0);
		v4_amount = new mutableInt(0);
		v5_amount = new mutableInt(0);
		
		B = new VStruct[PalionisRokas_L3a.array_limit];
		b_amount = new mutableInt(0);
		
		Proccess00Channel = proccess00Channel2;
	}
	
	public void run() {
		System.out.println("Process00 run method!");
		
		//Nuskaitomi pradiniai duomenys iš failo
		InputStream readStream = PalionisRokas_L3a.class.getResourceAsStream(PalionisRokas_L3a.filename);
		Scanner fileReader = new Scanner(readStream);
		try {
			readData(P1, V1, p1_amount, v1_amount, fileReader);
			readData(P2, V2, p2_amount, v2_amount, fileReader);
			readData(P3, V3, p3_amount, v3_amount, fileReader);
			readData(P4, V4, p4_amount, v4_amount, fileReader);
			readData(P5, V5, p5_amount, v5_amount, fileReader);
		} catch (IOException e1) {
			e1.printStackTrace();
		}
		fileReader.close();
		
		//Spausdinami pradiniai duomenys
		BufferedWriter fileWriter = null;
		try {
			fileWriter = new BufferedWriter(new FileWriter("src/PalionisRokas_L3a.rez.txt"));
		} catch (IOException e) {
			e.printStackTrace();
		}
		try {
			writeInitialData(P1, V1, p1_amount, v1_amount, fileWriter, 1);
			writeInitialData(P2, V2, p2_amount, v2_amount, fileWriter, 2);
			writeInitialData(P3, V3, p3_amount, v3_amount, fileWriter, 3);
			writeInitialData(P4, V4, p4_amount, v4_amount, fileWriter, 4);
			writeInitialData(P5, V5, p5_amount, v5_amount, fileWriter, 5);
		} catch (IOException e1) {
			e1.printStackTrace();
		}
		try {
			fileWriter.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		//Perduodami duomenys pridėjimo procesui
		Proccess00Channel[0].out().write(P1);
		Proccess00Channel[0].out().write(P2);
		Proccess00Channel[0].out().write(P3);
		Proccess00Channel[0].out().write(P4);
		Proccess00Channel[0].out().write(P5);
		
		//Perduodami duomenys šalinimo procesui
		Proccess00Channel[1].out().write(V1);
		Proccess00Channel[1].out().write(V2);
		Proccess00Channel[1].out().write(V3);
		Proccess00Channel[1].out().write(V4);
		Proccess00Channel[1].out().write(V5);
		
		//Gaunamas bendras masyvas B iš valdytojo
		B = (VStruct[]) Proccess00Channel[2].in().read();
		b_amount.setValue((int) Proccess00Channel[2].in().read());
		
		//Spausdinamas bendras masyvas B
		try {
			fileWriter = new BufferedWriter(new FileWriter("src/PalionisRokas_L3a.rez.txt", true));
		} catch (IOException e) {
			e.printStackTrace();
		}
		try {
			writeThreadsData(B, b_amount.getValue(), fileWriter);
		} catch (IOException e1) {
			e1.printStackTrace();
		}
		try {
			fileWriter.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public static void readData(PStruct P[], VStruct V[], mutableInt p_amount, mutableInt v_amount, Scanner fileScanner) throws IOException {
		//Elementų kiekvienoje sekcijoje skaičius
		int elements_amount = fileScanner.nextInt();
		p_amount.setValue(elements_amount);
		
		for(int i = 0; i < elements_amount; i++)
		    P[i] = new PStruct();
		fileScanner.nextLine();
		
		if (elements_amount > 0) {
			//Kol yra tinkamai įvestų objektų ir nepasiekia limito (array_element_limit), juos įrašo į masyvą
			for (int i = 0; fileScanner.hasNext() && i < PalionisRokas_L3a.array_element_limit && i < elements_amount; i++) {
				P[i].name = fileScanner.next();
				P[i].wins = fileScanner.nextInt();
				P[i].points = fileScanner.nextDouble();
			}
		}
		
		fileScanner.nextLine();
		
		elements_amount = fileScanner.nextInt();
		v_amount.setValue(elements_amount);
		
		for(int i = 0; i < elements_amount; i++)
		    V[i] = new VStruct();
		
		if (elements_amount > 0) {
			//Kol yra tinkamai įvestų objektų ir nepasiekia limito (array_element_limit), juos įrašo į masyvą
			for (int i = 0; fileScanner.hasNext() && i < PalionisRokas_L3a.array_element_limit && i < elements_amount; i++) {
				V[i].sorting_field = fileScanner.next();
				V[i].amount = fileScanner.nextInt();
			}
		}
		
		if (fileScanner.hasNext())
			fileScanner.nextLine();
	}
	
	public static void writeInitialData(PStruct P[], VStruct V[], mutableInt p_amount, mutableInt v_amount, BufferedWriter fileWriter, int element) throws IOException {		
		String lineSeparator = System.lineSeparator();
		
		//Išvedamos stulpelių antraštės
		fileWriter.write(element + " ---------------------------------" + lineSeparator);
		fileWriter.write("Nr. Nickname        Streak Score" + lineSeparator);
		
		for (int i = 0; i < p_amount.getValue() && P[i].name != "" && P[i].wins >= 0 && P[i].points >= 0; i++)
			fileWriter.write(String.format(" %-1d) %-14s %-8d %-2.2f " + lineSeparator, i + 1, P[i].name, P[i].wins, P[i].points));
		
		fileWriter.write(lineSeparator + "Nr. Sorting_Field Amount" + lineSeparator);

		for (int i = 0; i < v_amount.getValue() && V[i].sorting_field != "" && V[i].amount >= 0; i++)
			fileWriter.write(String.format(" %-1d) %-16s %-8d" + lineSeparator, i + 1, V[i].sorting_field, V[i].amount));
		
		fileWriter.write("-----------------------------------" + lineSeparator);
	}
	
	public static void writeThreadsData(VStruct B[], int b_amount, BufferedWriter fileWriter) throws IOException {		
		String lineSeparator = System.lineSeparator();
		fileWriter.write( lineSeparator +"------  Final data ------" + lineSeparator);
		fileWriter.write(lineSeparator + "Nr. Sorting_Field Amount" + lineSeparator);

		for (int i = 0; i < b_amount && B[i].sorting_field != "" && B[i].amount >= 0; i++)
			fileWriter.write(String.format(" %-1d) %-16s %-8d" + lineSeparator, i + 1, B[i].sorting_field, B[i].amount));
		
		fileWriter.write(" ---------------------------------" + lineSeparator);
	}
	
}

class ProcessAdd implements CSProcess {

	//Gijos numeris ir įvedimo bei išvedimo kanalai
	private int thread_number;
	private SharedChannelInput in;
	private SharedChannelOutput out;
	
	//Masyvas ir jo elementų identifikatorius
	private PStruct [] P;
	private mutableInt p_amount;
	
	public ProcessAdd(int i, SharedChannelInput sharedChannelInput, SharedChannelOutput out) {
		thread_number = i;
		this.in = sharedChannelInput;
		this.out = out;
		
		P = new PStruct[PalionisRokas_L3a.array_element_limit];
		p_amount = new mutableInt(0);		
	}

	public void run() {
		System.out.println("ProcessAdd[" + thread_number + "] run method!");
		
		//Gaunami duomenys iš Procesas00
		PStruct [] data = new PStruct[PalionisRokas_L3a.array_element_limit];
		data = (PStruct[]) in.read();
		
		if(data == null)
			System.out.println("[" + thread_number + "] data null");
		else
			P = data;
		
		int value = 0;
		for (int i = 0; i < P.length; i++) {
			if(P[i] != null)
				value++;
			else
				break;
		}
		
		p_amount.setValue(value);
		
		//Siunčiami duomenys valdytojui
		for(int i = 0; i < p_amount.getValue(); i++) {
			out.write(P[i]);
		}
		
		//Siunčiamas atsakas valdytojui
		out.write(null);
	}
	
}

class ProcessRemove implements CSProcess {

	//Gijos numeris ir įvedimo bei išvedimo kanalai
	private int thread_number;
	private SharedChannelInput in;
	private SharedChannelOutput out;
	private SharedChannelInput controllerIn;

	//Masyvas ir jo elementų identifikatorius
	private VStruct [] V;
	private mutableInt v_amount;
	
	//Ar baigė pildymo procesai
	private boolean finishedAdding;
	
	public ProcessRemove(int i, SharedChannelInput sharedChannelInput, SharedChannelOutput out, SharedChannelInput sharedChannelInput2) {
		thread_number = i;
		this.in = sharedChannelInput;
		this.out = out;
		
		V = new VStruct[PalionisRokas_L3a.array_element_limit];
		v_amount = new mutableInt(0);
		
		finishedAdding = false;
		
		controllerIn = sharedChannelInput2;
	}

	public void run() {
		System.out.println("ProcessDelete[" + thread_number + "] run method!");
		
		//Gaunami duomenys iš Procesas00
		VStruct [] data = new VStruct[PalionisRokas_L3a.array_element_limit];
		data = (VStruct[]) in.read();
		
		if(data == null)
			System.out.println("[" + thread_number + "] data null");
		else
			V = data;
		
		int value = 0;
		for (int i = 0; i < V.length; i++) {
			if(V[i] != null)
				value++;
			else
				break;
		}
		
		v_amount.setValue(value);

		while(!finishedAdding && v_amount.getValue() > 0) {
			//Siunčiami duomenys valdytojui
			for(int i = 0; i < v_amount.getValue(); i++) {
				out.write(V[i]);
				
				Integer response = null;
				while(response == null) {
					response = (Integer) controllerIn.read();
				}
				if(response == 1) {
					finishedAdding = true;
				}
				else if(response == 2) {
					finishedAdding = true;
					i = -1;
				}
			}
		}
		
		//Siunčiamas atsakas valdytojui
		out.write(null);
	}
	
}

class Controller implements CSProcess {


	private VStruct [] B;
	private mutableInt b_amount;

	private int thread_amount;
	

	private Any2OneChannel addChannel;
	private Any2OneChannel removeChannel;
	private ChannelOutput out;
	private One2AnyChannel controller;
	

	int finishedAdding;
	int finishedRemoving;
	
	public Controller(int threadAmount, Any2OneChannel addChannel2, Any2OneChannel removeChannel2, ChannelOutput channelOutput, One2AnyChannel controller) {
		B = new VStruct[PalionisRokas_L3a.array_limit];
		b_amount = new mutableInt(0);
		
		for(int i = 0; i < PalionisRokas_L3a.array_limit; i++)
		    B[i] = new VStruct();
		
		this.thread_amount = threadAmount;
		
		this.addChannel = addChannel2;
		this.removeChannel = removeChannel2;
		
		this.out = channelOutput;
		
		finishedAdding = 0;
		finishedRemoving = 0;
		
		this.controller = controller;
	}

	public void run() {
		System.out.println("Controller run method!");

		Alternative alternative = new Alternative(createGuards());

		while(finishedAdding != thread_amount || finishedRemoving != thread_amount) {
			int channel = alternative.fairSelect(); 
	        if (channel == 0)
	            addElement();
	        else
	            removeElement();
		}
        
        //Išsiunčiamas bendras masyvas B spausdinimui į Procesas00
        out.write(B);
        out.write(b_amount.getValue());
	}
	
    private Guard[] createGuards() {
        Guard[] guards = new Guard[2];
        guards[0] = addChannel.in();
        guards[1] = removeChannel.in();
        
        return guards;
    }
	
    private void addElement() {
    	PStruct element = new PStruct();
    	element = (PStruct) addChannel.in().read();
    	
    	if(element == null) {
    		finishedAdding++;
    	} else {
    		addElementToArray(element);
    	}
    }
    
    private void addElementToArray(PStruct element) {
		//Masyvo vietos paieškos indeksas
		int index = -1;

		//Ieškoma įterpimo vieta
		for (int i = 0; i <= b_amount.getValue() && B[i] != null; i++)
			if (element.name.equals(B[i].sorting_field))
				index = i;

		//Jei vieta rasta - prie kiekio prideda 1, kitu atveju jeigu dar masyve yra vietos suranda indeksą ir ten įdeda duomenis
		if (index > -1) {
			B[index].amount++;
		}
		else {
			if (b_amount.getValue() < PalionisRokas_L3a.array_limit) {
				//Indeksas nustatomas į masyvo pradžią
				index = 0;

				//Ieškomas įterpimo indeksas
				for (int i = 0; i <= b_amount.getValue() && B[i] != null; i++) {
					//Reikšmės rikiavimas didėjimo tvarka (>), mažėjimo (<)
					if (element.name.compareTo(B[i].sorting_field) > 0) {
						index = i;
					}
					else {
						index = i;
						break;
					}
				}

				//Pastumia elementus į galą nuo įterpiamojo elemento
				for (int i = b_amount.getValue(); i >= index && B[i] != null; i--) {
					B[i + 1].sorting_field = B[i].sorting_field;
					B[i + 1].amount = B[i].amount;
				}

				//Įrašo naujus duomenis į atsilaisvinusią vietą
				B[index] = new VStruct();
				B[index].sorting_field = element.name;
				B[index].amount = 1;
				//Padidina masyvo indeksą
				b_amount.setValue(b_amount.getValue() + 1);
			}
		}

		//cout << "\t\tAddElement thread added: " << P.name << "!" << endl;
		System.out.println("\t\tAddElement thread added: " + element.name + "!\n");
    }
    
    private void removeElement() {
    	VStruct element = new VStruct();
    	element = (VStruct) removeChannel.in().read();
    	
    	if(element == null) {
    		finishedRemoving++;
    	} else {
    		boolean wasRemoved = removeElementFromArray(element);
    		
    		if(finishedAdding != thread_amount)
    			controller.out().write(0);
    		else if(!wasRemoved)
    			controller.out().write(1);
    		else
    			controller.out().write(2);
    	}
    }
    
    private boolean removeElementFromArray(VStruct element) {
		boolean elementFound = false;

		for (int i = 0; i <= b_amount.getValue(); i++) {
			//Jei rasta šalinama reikšmė
			if (element.sorting_field.equals(B[i].sorting_field)) {
				System.out.println("\t\tRemoveElement thread found: " + element.sorting_field + "!\n");

				//Tikrina ar trinti duomenis, ar sumažinti 1, ar nieko nedaryti ir laukti kol užsipildys
				if (B[i].amount - element.amount > 0) {
					B[i].amount -= element.amount;

					elementFound = true;

					System.out.println("\t\tRemoveElement thread modiffied: " + element.sorting_field + "!\n");

					return elementFound;
				}
				else {
					//Pastumiami likę elementai
					for (int j = i; j <= b_amount.getValue() - 1; j++) {
						B[j].sorting_field = B[j + 1].sorting_field;
						B[j].amount = B[j + 1].amount;
					}

					//Sumažinamas masyvo indeksas
					b_amount.setValue(b_amount.getValue() - 1);

					elementFound = true;

					System.out.println("\t\tRemoveElement thread removed: " + element.sorting_field + "!\n");

					return elementFound;
				}
			}
		}

		if (!elementFound) {
//			System.out.println("\t\tRemoveElement thread didn't found: " + element.sorting_field + "!\n");
		}
		
		return elementFound;
    }
    
}