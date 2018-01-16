class ProduceFromTop implements Runnable{
    int number;
    ProduceFromTop(int number){
        this.number=number;
    }
    @Override
    public void run() {
        System.out.println("Thread "+number+" has started!");
        try {
            Thread.sleep(4000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        for (int i = 95+number; i >=0 ; i-=2) {
            //System.out.println(i);
            if (Test.monitor.counter2==100||Test.monitor.array[i]!=0)
                break;
           Test.monitor.addToArray(number,i);
        }
        if (Test.monitor.counter2==100)
        Test.finished=true;
        System.out.println("Thread "+number+" has ended!");
    }
}
class Produce implements Runnable{
    int number;
    Produce(int number){
        this.number=number;
    }
    @Override
    public void run() {
        System.out.println("Thread "+number+" has started!");

        try {
            Thread.sleep(4000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        for (int i = number-1; i <100 ; i+=2) {
            if (Test.monitor.counter2==100||Test.monitor.array[i]!=0)
                break;
            Test.monitor.addToArray(number,i);
        }
        if (Test.monitor.counter2==100)
        Test.finished=true;
        System.out.println("Thread "+number+" has ended!");
    }
}
class Announcer implements Runnable{
    int number;
    Announcer(int number){this.number=number;}
    @Override
    public void run() {
        System.out.println("Thread "+number+" has started!");
        while (Test.monitor.counter2<=100){
            Test.monitor.printArray();
            if (Test.finished==true){
                break;
            }
        }
        System.out.println("Thread "+number+" has ended!");
    }
}
class Monitor {
    int[] array;
    int count;
    int counter2;
    Monitor(){
        this.array=new int[100];
        for (int i = 0; i <100 ; i++) {
            array[i]=0;
        }
        count=0;
        counter2=0;
    }
    public synchronized void addToArray(int number, int index){
            try {
                while (count==10) {
                    wait();
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            array[index]=number;
            count++;
            counter2++;
            notifyAll();
        }
        public synchronized void printArray(){
                try {
                    while (count!=10) wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                String arrayString="";
            for (int i = 0; i <array.length ; i++) {
                arrayString+=Integer.toString(array[i]);
                //System.out.print(array[i]);
            }
            count=0;
            System.out.println(arrayString);
                notifyAll();
        }
}
public class Test {
    static volatile Monitor monitor = new Monitor();
    static volatile boolean finished = false;
    public static void main(String[] args) throws InterruptedException {
        Thread t1 = new Thread(new Produce(1));
        Thread t2 = new Thread(new ProduceFromTop(3));
        Thread t4 = new Thread(new Produce(2));
        Thread t5 = new Thread(new ProduceFromTop(4));
        Thread t3 = new Thread(new Announcer(5));
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

    }
}
