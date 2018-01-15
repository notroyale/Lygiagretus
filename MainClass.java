class Producer implements Runnable{
    String[] array;
    int number;
    int counter;
    Producer(String[] array,int number){
        this.array=array;
        this.counter=0;
        this.number=number;
    }

    @Override
    public void run(){
        while (counter<array.length){
            MainClass.monitor.addSymbol(array[counter],number);
            counter++;
            if (MainClass.counter>=15)break;
        }
    }
}
class Printer implements Runnable{
    int id;
    Printer(int id){
        this.id=id;
    }
    @Override
    public void run(){
        while (MainClass.counter<15){
            MainClass.monitor.readString(id);
        }
    }
}
class Monitor{
    String string;
    Monitor(){
        this.string="*";
    }
    synchronized void readString(int threadID){
        while (MainClass.lastPrinted.equals(string)&&MainClass.counter<15) {
            try {
                /*System.out.println("uzmigo Thread id "+threadID+" counter "+MainClass.counter);*/wait();/*System.out.println("pabudo");*/
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        if(MainClass.counter>=15){
            return;
        }
        System.out.println("Thread ID = "+threadID+" Current string - "+string+"  string lenght = "+string.length());
        MainClass.lastPrinted=string;
        MainClass.isReaded=true;
        notifyAll();
        MainClass.counter++;
    }
    synchronized void addSymbol(String symbol, int threadID){
        if (MainClass.counter>=15){
            return;
        }
        while (!MainClass.isReaded&&MainClass.counter<15) {
            try {
                wait();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        if (MainClass.counter>=15){
            return;
        }
        string+=symbol;
        MainClass.isReaded=false;
        notifyAll();
    }
}
public class MainClass {
    public static volatile Monitor monitor = new Monitor();
    public static volatile int counter = 0;
    public static volatile boolean isReaded = true;
    public static volatile String lastPrinted ="";
    public static void main(String[] args) throws InterruptedException {
        String[] array1 = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","r","s","t","u","v","z"};
        String[] array2 = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","R","S","T","U","V","Z"};
        String[] array3 = {"0","1","2","3","4","5","6","7","8","9"};
        Thread t1 = new Thread(new Producer(array1,1));
        Thread t2 = new Thread(new Producer(array2,2));
        Thread t3 = new Thread(new Producer(array3,3));
        Thread t4 = new Thread(new Printer(4));
        Thread t5 = new Thread(new Printer(5));

        t1.start();
        t2.start();
        t3.start();
        t4.start();
        t5.start();

        t1.join();
        t2.join();
        t3.join();
        t4.join();
        t5.join();
        System.out.println();
        System.out.println("Galutinis string = "+monitor.string+" Lenght = "+monitor.string.length());

    }

}