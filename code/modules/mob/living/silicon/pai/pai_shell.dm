
/mob/living/silicon/pai/proc/fold_out(force = FALSE)
	if(emitterhealth < 0)
		to_chat(src, span_warning("Your holochassis emitters are still too unstable! Please wait for automatic repair."))
		return FALSE

	if(!canholo && !force)
		to_chat(src, span_warning("Your master or another force has disabled your holochassis emitters!"))
		return FALSE

	if(holoform)
		. = fold_in(force)
		return

	if(emittersemicd)
		to_chat(src, span_warning("Error: Holochassis emitters recycling. Please try again later."))
		return FALSE

	emittersemicd = TRUE
	addtimer(CALLBACK(src, PROC_REF(emittercool)), emittercd)
	mobility_flags = MOBILITY_FLAGS_DEFAULT
	density = TRUE
	if(istype(card.loc, /obj/item/pda))
		var/obj/item/pda/P = card.loc
		P.pai = null
		P.visible_message(span_notice("[src] ejects itself from [P]!"))
	if(isliving(card.loc))
		var/mob/living/L = card.loc
		if(!L.temporarilyRemoveItemFromInventory(card))
			to_chat(src, span_warning("Error: Unable to expand to mobile form. Chassis is restrained by some device or person."))
			return FALSE
	forceMove(get_turf(card))
	card.forceMove(src)
	if(client)
		client.perspective = EYE_PERSPECTIVE
		client.eye = src
	set_light(0)
	icon_state = "[chassis]"
	held_state = "[chassis]"
	visible_message(span_boldnotice("[src] folds out its holochassis emitter and forms a holoshell around itself!"))
	holoform = TRUE

/mob/living/silicon/pai/proc/emittercool()
	emittersemicd = FALSE

/mob/living/silicon/pai/proc/fold_in(force = FALSE)
	emittersemicd = TRUE
	if(!force)
		addtimer(CALLBACK(src, PROC_REF(emittercool)), emittercd)
	else
		addtimer(CALLBACK(src, PROC_REF(emittercool)), emitteroverloadcd)
	icon_state = "[chassis]"
	if(!holoform)
		. = fold_out(force)
		return
	visible_message(span_notice("[src] deactivates its holochassis emitter and folds back into a compact card!"))
	stop_pulling()
	if(client)
		client.perspective = EYE_PERSPECTIVE
		client.eye = card
	var/turf/T = drop_location()
	card.forceMove(T)
	forceMove(card)
	mobility_flags = NONE
	density = FALSE
	set_light(0)
	holoform = FALSE
	set_resting(resting)

/mob/living/silicon/pai/proc/choose_chassis()
	if(!isturf(loc) && loc != card)
		to_chat(src, span_boldwarning("You can not change your holochassis composite while not on the ground or in your card!"))
		return FALSE
	var/choice = input(src, "What would you like to use for your holochassis composite?") as null|anything in possible_chassis
	if(!choice)
		return FALSE
	chassis = choice
	icon_state = "[chassis]"
	held_state = "[chassis]"
	update_resting()
	to_chat(src, span_boldnotice("You switch your holochassis projection composite to [chassis]."))

/mob/living/silicon/pai/update_resting()
	. = ..()
	if(resting)
		icon_state = "[chassis]_rest"
	else
		icon_state = "[chassis]"
	if(loc != card)
		visible_message(span_notice("[src] [resting? "lays down for a moment..." : "perks up from the ground."]"))

/mob/living/silicon/pai/start_pulling(atom/movable/AM, state, force = move_force, supress_message = FALSE)
	return FALSE

/mob/living/silicon/pai/proc/toggle_integrated_light()
	if(!light_range)
		set_light(brightness_power)
		to_chat(src, span_notice("You enable your integrated light."))
	else
		set_light(0)
		to_chat(src, span_notice("You disable your integrated light."))

/mob/living/silicon/pai/mob_try_pickup(mob/living/user)
	if(!possible_chassis[chassis])
		to_chat(user, span_warning("[src]'s current form isn't able to be carried!"))
		return FALSE
	return ..()
