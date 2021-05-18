# LookingGlassUI

A SwiftUI view 3d rotation effect modifier that's connected to core motion and allows views to appear projected in a specific direction relative to the device in real space.

In window mode a view appears as if your phone is a window looking into a 3d environment.
In reflection mode a view appears as if your phone has a camera pointing out of the screen back at a 3d envrionment. It's not a true reflection as it doesn't take into account the viewer's eye location but it's a useful approximation.

Views are positioned based on a quaternion or simple pitch, roll, and yaw angles.
All angles at zero means the view will be visible when the phone is flat with the top pointing away from the user.
Pitch of 90 degrees will bring the view up directly in front of the user.
Yaw will move the view to the left or right.
Roll will rock the vew down to the right or left.
