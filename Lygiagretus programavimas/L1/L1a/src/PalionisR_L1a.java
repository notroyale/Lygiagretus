/*
 * Rokas Palionis IFF-5/8
 * 
 * 1. Kokia tvarka startuoja procesai? Galimi atsakymo variantai: tokia, kokia užrašyti, atsitiktine, atvirkščia.
 * 		Atsakymas: Tokia, kokia užrašyti.
 * 2. Kokia tvarka vykdomi procesai? Galimi atsakymo variantai: tokia, kokia startuoja, atsitiktine, atvirkščia.
 * 		Atsakymas: Atsitiktine.
 * 3. Kiek iteracijų iš eilės padaro vienas procesas? Galimi atsakymo variantai: vienos dalį, vieną pilnai, visas,
 * atsitiktinį skaičių.
 * 		Atsakymas: Vieną pilnai.
 * 4. Kokia tvarka to paties duomenų masyvo elementai surašomi į rezultatų masyvą? Galimi atsakymo variantai:
 * tokia, kokia surašyti duomenų masyve, atsitiktine, atvirkščia.
 * 		Atsakymas: Tokia, kokia surašyti duomenų masyve.
 * 
 */

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;
import java.util.Scanner;

public class PalionisR_L1a extends Thread {

	//Gijos vardas
	private String name;
	//Gijos masyvas
	private String [] Pn;
	
	//Bendras masyvas ir kiek jame yra reikšmių
	private static String [] P = new String[5*9];
	//Paskutiniojo įterpiamo elemento vieta
	private static int elementsAmount = 0;
	
	public PalionisR_L1a(String name, String [] Pn) {
		this.name = name;
		this.Pn = Pn;
	}
	
	public static void main(String[] args) throws IOException {
		//Sukuriami masyvai duomenų rinkiniams saugoti
		String [] P1 = new String[10];
		String [] P2 = new String[10];
		String [] P3 = new String[10];
		String [] P4 = new String[10];
		String [] P5 = new String[10];
		
		readData(P1, P2, P3, P4, P5);		
		writeData(P1, P2, P3, P4, P5);
		
		executeThreads(P1, P2, P3, P4, P5);
		writeThreads(P);
		
		System.out.println("Programa baigė darbą.");
	}
	
	public static void readData(String [] P1, String [] P2, String [] P3, String [] P4, String [] P5) throws IOException {
		InputStream readStream = PalionisR_L1a.class.getResourceAsStream("PalionisR_L1a.dat.txt");
		Scanner fileScanner = new Scanner(readStream);
		
		//Nuskaitinėja grupių pavadinimus
		for (int i = 1; i <= 5 && fileScanner.hasNextLine(); i++) {
			switch(i) {
				case 1:
					P1[0] = fileScanner.next();
					break;
				case 2:
					P2[0] = fileScanner.next();
					break;
				case 3:
					P3[0] = fileScanner.next();
					break;
				case 4:
					P4[0] = fileScanner.next();
					break;
				case 5:
					P5[0] = fileScanner.next();
					break;
			}

			int amount = fileScanner.nextInt();
			
			fileScanner.nextLine();
			
			for (int j = 1; j <= amount && fileScanner.hasNextLine(); j++) {
				switch(i) {
					case 1:
						P1[j] = fileScanner.nextLine();
						break;
					case 2:
						P2[j] = fileScanner.nextLine();
						break;
					case 3:
						P3[j] = fileScanner.nextLine();
						break;
					case 4:
						P4[j] = fileScanner.nextLine();
						break;
					case 5:
						P5[j] = fileScanner.nextLine();
						break;
				}
			}
		}
		
		fileScanner .close();
	}

	public static void writeData(String [] P1, String [] P2, String [] P3, String [] P4, String [] P5) throws IOException {		
		BufferedWriter fileWriter = new BufferedWriter(new FileWriter("src/PalionisR_L1a.rez.txt"));
		
		//Įrašinėja grupių pavadinimus
		for (int i = 1; i <= 5; i++) {
			fileWriter.write("---- ");
			
			switch(i) {
				case 1:
					fileWriter.write(P1[0]);
					break;
				case 2:
					fileWriter.write(P2[0]);
					break;
				case 3:
					fileWriter.write(P3[0]);
					break;
				case 4:
					fileWriter.write(P4[0]);
					break;
				case 5:
					fileWriter.write(P5[0]);
					break;
			}
			
			fileWriter.write(" ----\n");
			
			fileWriter.write(String.format("   %-14s %-6s %-5s\n", "Vardas", "Pergalės", "Taškai"));
			
			Scanner lineScanner = new Scanner("");
			Locale.setDefault(Locale.US);
			
			//Įrašinėja grupių elementus
			for (int j = 1; j <= P1.length - 1; j++) {
				switch(i) {
					case 1:
						if(P1[j] != null) {
							lineScanner = new Scanner(P1[j]);

							String player = lineScanner.next();
							int wins = lineScanner.nextInt();
							double points = lineScanner.nextDouble();
							
							fileWriter.write(String.format("%-1d) %-14s %-8d %-2.2f\n", j, player, wins, points));
						}
						break;
					case 2:
						if(P2[j] != null) {
							lineScanner = new Scanner(P2[j]);

							String player = lineScanner.next();
							int wins = lineScanner.nextInt();
							double points = lineScanner.nextDouble();
							
							fileWriter.write(String.format("%-1d) %-14s %-8d %-2.2f\n", j, player, wins, points));
						}
						break;
					case 3:
						if(P3[j] != null) {
							lineScanner = new Scanner(P3[j]);

							String player = lineScanner.next();
							int wins = lineScanner.nextInt();
							double points = lineScanner.nextDouble();
							
							fileWriter.write(String.format("%-1d) %-14s %-8d %-2.2f\n", j, player, wins, points));
						}
						break;
					case 4:
						if(P4[j] != null) {
							lineScanner = new Scanner(P4[j]);

							String player = lineScanner.next();
							int wins = lineScanner.nextInt();
							double points = lineScanner.nextDouble();
							
							fileWriter.write(String.format("%-1d) %-14s %-8d %-2.2f\n", j, player, wins, points));
						}
						break;
					case 5:
						if(P5[j] != null) {
							lineScanner = new Scanner(P5[j]);

							String player = lineScanner.next();
							int wins = lineScanner.nextInt();
							double points = lineScanner.nextDouble();
							
							fileWriter.write(String.format("%-1d) %-14s %-8d %-2.2f\n", j, player, wins, points));
						}
						break;
				}
			}
			
			lineScanner.close();
		}
		
		fileWriter.write("\nRezultatų pabaiga\n\n");
		
		fileWriter.close();
	}

	public static void writeThreads(String [] P) throws IOException {
		BufferedWriter fileWriter = new BufferedWriter(new FileWriter("src/PalionisR_L1a.rez.txt", true));
		
		Scanner lineScanner = new Scanner("");
		Locale.setDefault(Locale.US);
		
		//Išvedami bendro masyvo P elementai
		for(int i = 0; i < P.length - 1; i++)
			if(P[i] != null) {
				lineScanner = new Scanner(P[i]);

				String name = lineScanner.next();
				int number = lineScanner.nextInt();
				String player = lineScanner.next();
				int wins = lineScanner.nextInt();
				double points = lineScanner.nextDouble();
				
				fileWriter.write(String.format("%-10s %-1d %-14s %-8d %-2.2f\n", name, number, player, wins, points));
			}
		
		lineScanner.close();
		
		fileWriter.close();
	}
	
	public static void executeThreads(String [] P1, String [] P2, String [] P3, String [] P4, String [] P5) {
		//Sukuriamos 5 naujos gijos ir pateikiami skirtingi masyvai kiekvienai iš jų
		Thread thread_1 = new Thread(new PalionisR_L1a("gija_1", P1));
		Thread thread_2 = new Thread(new PalionisR_L1a("gija_2", P2));
		Thread thread_3 = new Thread(new PalionisR_L1a("gija_3", P3));
		Thread thread_4 = new Thread(new PalionisR_L1a("gija_4", P4));
		Thread thread_5 = new Thread(new PalionisR_L1a("gija_5", P5));
		
		thread_1.start(); thread_2.start(); thread_3.start(); thread_4.start(); thread_5.start();
		

		while (thread_1.isAlive() || thread_2.isAlive() || thread_3.isAlive() || thread_4.isAlive() || thread_5.isAlive()) {}
	}
	
	public void run() {
		switch(name) {
			case "gija_1":
				for(int i = 1; i < Pn.length - 1; i++)
					if(Pn[i] != null)
						P[elementsAmount++] = name + " " + i + " " + Pn[i];
				break;
			case "gija_2":
				for(int i = 1; i < Pn.length - 1; i++)
					if(Pn[i] != null)
						P[elementsAmount++] = name + " " + i + " " + Pn[i];
				break;
			case "gija_3":
				for(int i = 1; i < Pn.length - 1; i++)
					if(Pn[i] != null)
						P[elementsAmount++] = name + " " + i + " " + Pn[i];
				break;
			case "gija_4":
				for(int i = 1; i < Pn.length - 1; i++)
					if(Pn[i] != null)
						P[elementsAmount++] = name + " " + i + " " + Pn[i];
				break;
			case "gija_5":
				for(int i = 1; i < Pn.length - 1; i++)
					if(Pn[i] != null)
						P[elementsAmount++] = name + " " + i + " " + Pn[i];
				break;
		}
	}
	
};