/obj/machinery/anesthetic_machine
	name = "Anesthetic Tank Holder"
	desc = "A wheeled machine that can hold an anesthetic tank and distribute the air using a breath mask."
	icon = 'icons/obj/iv_drip.dmi'
	icon_state = "breath_machine"
	anchored = FALSE
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	var/obj/item/clothing/mask/breath/machine/attached_mask
	var/obj/item/tank/attached_tank = null
	var/is_roundstart = FALSE
	var/mask_out = FALSE

/obj/machinery/anesthetic_machine/roundstart
	is_roundstart = TRUE

/obj/machinery/anesthetic_machine/Initialize(mapload)
	. = ..()
	attached_mask = new /obj/item/clothing/mask/breath/machine(src)
	attached_mask.machine_attached = src
	if(is_roundstart)
		var/obj/item/tank/T = new /obj/item/tank/internals/anesthetic(src)
		attached_tank = T
	update_appearance(UPDATE_ICON)

/obj/machinery/anesthetic_machine/update_overlays()
	. = ..()
	if(mask_out)
		. += "mask_off"
	else
		. += "mask_on"
	if(attached_tank)
		. += "tank_on"


/obj/machinery/anesthetic_machine/attack_hand(mob/living/user)
	. = ..()
	if(retract_mask())
		visible_message("<span class='notice'>[user] retracts the mask back into the [src].</span>")

/obj/machinery/anesthetic_machine/attacked_by(obj/item/I, mob/living/user)
	if(istype(I, /obj/item/tank))
		if(attached_tank) // If there is an attached tank, remove it and drop it on the floor
			attached_tank.forceMove(loc)
		I.forceMove(src) // Put new tank in, set it as attached tank
		visible_message("<span class='warning'>[user] inserts [I] into [src].</span>")
		attached_tank = I
		update_appearance(UPDATE_ICON)
		return
	. = ..()

/obj/machinery/anesthetic_machine/AltClick(mob/user)
	. = ..()
	if(attached_tank)// If attached tank, remove it.
		attached_tank.forceMove(loc)
		to_chat(user, "<span class='notice'>You remove the [attached_tank].</span>")
		attached_tank = null
		update_appearance(UPDATE_ICON)
		if(mask_out)
			retract_mask()

/obj/machinery/anesthetic_machine/proc/retract_mask()
	if(mask_out)
		if(iscarbon(attached_mask.loc)) // If mask is on a mob
			var/mob/living/carbon/M = attached_mask.loc
			M.transferItemToLoc(attached_mask, src, TRUE)
			M.close_externals()
		else
			attached_mask.forceMove(src)
		mask_out = FALSE
		update_appearance(UPDATE_ICON)
		return TRUE
	return FALSE

/obj/machinery/anesthetic_machine/MouseDrop(mob/living/carbon/target)
	. = ..()
	if(!iscarbon(target))
		return
	if(src.Adjacent(target) && usr.Adjacent(target))
		if(attached_tank && !mask_out)
			usr.visible_message("<span class='warning'>[usr] attempts to attach the [src] to [target].</span>", "<span class='notice'>You attempt to attach the [src] to [target].</span>")
			if(do_after(usr, 5 SECONDS, target, TRUE))
				if(!target.equip_to_appropriate_slot(attached_mask))
					to_chat(usr, "<span class='warning'>You are unable to attach the [src] to [target]!</span>")
					return
				else
					usr.visible_message("<span class='warning'>[usr] attaches the [src] to [target].</span>", "<span class='notice'>You attach the [src] to [target].</span>")
					target.open_internals(attached_tank, TRUE)
					mask_out = TRUE
					START_PROCESSING(SSmachines, src)
					update_appearance(UPDATE_ICON)
		else
			to_chat(usr, "<span class='warning'>[mask_out ? "The machine is already in use!" : "The machine has no attached tank!"]</span>")

/obj/machinery/anesthetic_machine/process()
	if(!mask_out) // If not on someone, stop processingI c
		return PROCESS_KILL

	if(get_dist(src, get_turf(attached_mask)) > 1) // If too far away, detach
		to_chat(attached_mask.loc, "<span class='warning'>The [attached_mask] is ripped off of your face!</span>")
		retract_mask()
		return PROCESS_KILL

/obj/machinery/anesthetic_machine/Destroy()
	if(mask_out)
		retract_mask()
	qdel(attached_mask)
	new /obj/item/clothing/mask/breath(src)
	. = ..()

/obj/item/clothing/mask/breath/machine
	var/obj/machinery/anesthetic_machine/machine_attached
	clothing_flags = MASKINTERNALS | MASKEXTENDRANGE

/obj/item/clothing/mask/breath/machine/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)

/obj/item/clothing/mask/breath/machine/dropped(mob/user)
	. = ..()
	if(loc != machine_attached) // If not already in machine, go back in when dropped (dropped is called on unequip)
		to_chat(user, "<span class='notice'>The mask snaps back into the [machine_attached].</span>")
		machine_attached.retract_mask()
