The only controller action:

```
  def sleep
    t1 = Time.now.to_i
    seconds = params[:seconds].to_i
    Kernel.sleep(seconds)
    t2 = Time.now.to_i
    render plain: (t2 - t1).to_s
  end
```

The heart of hammer.sh:

```
for n in $(seq 5 -1 1); do
	curl --silent "http://localhost:3000/sleep?seconds=${n}" &
	sleep 0.1
done
```

Run the server with a single process and a single thread:

```
SECRET_KEY_BASE=c9bea0e4-16c4-4256-b0dc-7ad013b18705 bex puma --environment production -w 1 -t 1:1
```

Run the hammer script. It will initiate 5 requests that ask the server to sleep for a different number of seconds, start with 5 and decrementing to 1.

```
time bash hammer.sh
```

It should output:

```
54321

real    0m15.033s
user    0m0.052s
sys     0m0.022s
```

This is because each request is blocked by the one before it. We start with a request that takes 5 seconds, followed by a request that takes 4 seconds, 3, 2, 1.

Restart the server and make it always use 5 threads:

```
SECRET_KEY_BASE=c9bea0e4-16c4-4256-b0dc-7ad013b18705 bex puma --environment production -w 1 -t 5:5
```

Now the script should output:

```
12345

real    0m5.026s
user    0m0.045s
sys     0m0.027s
```

All of the requests arrive before 1 second has elapsed. The thread pool is never exhausted. Thus, each request is handled by a separate thread. Each thread wakes up and outputs how long it has slept before the next thread wakes up. Therefore the output is predictable.


Restart the server once more and make it use between 1 and 2 threads:

```
SECRET_KEY_BASE=c9bea0e4-16c4-4256-b0dc-7ad013b18705 bex puma --environment production -w 1 -t 1:3
```

Now the output is less ordered:

```
time bash hammer.sh 
34512

real    0m5.229s
user    0m0.046s
sys     0m0.026s
```

The requests all still arrive in the order 5-4-3-2-1 but the order of the output will usually be 3-4-5-1-2. This is because the thread pool will grow on-demand up to 3 threads. The determinism here is caused by the `sleep 0.1` in `hammer.sh`. It causes the order to be:

0.0s Req 5 queued for thread 0
0.1s Req 4 queued for thread 1
0.2s Req 3 queued for thread 2
0.3s Req 2 blocks on the empty thread pool
0.4s Req 1 blocks on the empty thread pool
3.2s Thread 2 wakes up, finishes req 3, picks up req 2
4.1s Thread 1 wakes up, finishes req 4, picks up req 1
5.1s Thread 1 wakes up, finishes req 1
5.2s Thread 2 wakes up, finishes req 2

The precise order and timings are subject to the randomness of the thread creation overhead, operating system schedule, hardware interupts, etc. Therefore the order might come out slightly differently in some cases. You could multiply all the sleep times by 10 to avoid that but it would be painful to run the demo :)


