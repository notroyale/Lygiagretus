/**
 * Created by Rokas on 1/15/2018.
 */
public class pvz {

    public static volatile Monitor monitor = new Monitor();
    public static volatile int removeCounter = 20000;
    public static void main(String[] args) throws InterruptedException {
        Thread t1 = new Thread(new Sender(1));
        Thread t2 = new Thread(new Sender(2));
        Thread t3 = new Thread(new Sender(3));
        Thread t4 = new Thread(new Remover(4));
        Thread t5 = new Thread(new Remover(5));
        t1.start();
        t2.start();
        t3.start();
        t1.join();
        t2.join();
        t3.join();
        //for (int i = 0; i < 100; i++) {
          //  System.out.print(monitor.array[i]);
        //}
        //System.out.println();
        t4.start();
        t5.start();
        t4.join();
        t5.join();
        for (int i = 0; i < 100; i++) {
            System.out.print(monitor.array[i]);
        }



    }
}

class Sender implements Runnable {

    int number;
    Sender(int number){
        this.number=number;
    }
    @Override
    public void run() {
        for (int i = number-1; i <100 ; i+=3) {
            pvz.monitor.addToArray(i,number);
            if (pvz.removeCounter<=0)break;
        }
    }
}

class Remover implements Runnable {

    int number;
    Remover(int number) {

        this.number=number;
    }

    @Override
    public void run() {
        for (int i = number-1; i < 100; i+=number) {
            pvz.monitor.removeFromArray(i);
            if(pvz.removeCounter <=0) break;
        }

    }
}

class Monitor {



    int[] array;
    int[] removeArray;
     Monitor() {
         this.array= new int[100];
         this.removeArray= new int[100];
         for (int i = 0; i < 100; i++) {
             array[i]=0;
         }

     }
     synchronized void addToArray(int index,int number){
         if (pvz.removeCounter<=0)return;
         array[index]=number;
         notifyAll();
     }
     synchronized  void removeFromArray(int index) {

         if(pvz.removeCounter <=0||removeArray[index]==1) return;
         try {
             while (array[index]==0)
             {System.out.println("uzmigo  "+ index+ " "+pvz.removeCounter);wait(); System.out.println("Pabudo " + index + "  "+ pvz.removeCounter);}
         } catch (InterruptedException e) {
             e.printStackTrace();
         }
         array[index]=0;
         removeArray[index]=1;
         System.out.println(index);
         pvz.removeCounter--;

     }



}
