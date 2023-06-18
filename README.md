# event_tracker


## How to use the app:

### 1. Two Concepts: ``Events`` and ``Records``:

An ``event`` is a kind of action or activity in your daily life. 

An ``record`` is an occurrence of the corresponding event. Record is inputted by user in the following effective way.

For every ``event``, the user can choose whether it is with or without ``unit``, and with or without ``duration``, thus creating **four categories of events**. 

![image](https://user-images.githubusercontent.com/32631191/134082705-465f6309-e297-468b-9c36-4ece0131278c.png)



---
### 2. Interaction About Recording:
For an ``event`` with duration, when it starts, a timer is automatically triggered; when it ends, the user clicks the end button and potentially input the value of the bound ``unit``. Then the corresponding ``record`` with its duration and value of ``unit`` will be generated and stored. 

Note: By long pressing the ``event``, the user can manually input a former time as its starting or ending time. Simultaneous-running events are allowed ant all events' status will not be disrupted by terminating the app.

For an ``event`` without duration, we only care about its ending time. A short press adds a  ``record`` of it with current time as the end time. To enter a former time as end time, a long press is needed. (Value of unites may be inputted depending on whether the event is bound with a unit).


---
### 3. Interaction About Viewing Summary and Details:

---
### Some screenshots (in Chinese):


![1](https://user-images.githubusercontent.com/32631191/132087007-d03bd8db-2881-4c79-abd3-d71464ac54f7.png)
![2](https://user-images.githubusercontent.com/32631191/132087009-c2f94a7b-da89-4f70-92f1-3610623b0e25.png)
![3](https://user-images.githubusercontent.com/32631191/132087010-b2477b0a-491f-4230-aca3-333baa88ed42.png)
![4](https://user-images.githubusercontent.com/32631191/132087012-225b027d-9cc9-423e-93df-8c0bd3bd4e67.png)
![5](https://user-images.githubusercontent.com/32631191/132087014-ba140a2a-1cdc-443d-8061-45ac7c63e813.png)
