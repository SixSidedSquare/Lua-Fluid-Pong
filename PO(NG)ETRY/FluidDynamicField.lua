-- Fluid dynamics code from Jos Stam's paper here:  http://www.dgp.toronto.edu/people/stam/reality/index.html

function initField(inWidth, inHeight, indiff, invisc)
	fieldWidth = inWidth
	fieldHeight = inHeight
	diff = indiff
	visc = invisc

	u = {}
	v = {}
	u_prev = {}
	v_prev = {}
	dens = {}
	dens_prev = {}
	
	size = (inWidth + 2) * (inHeight * 2)
	
    for i=0,size-1 do
		u[i] = 0
		v[i] = 0
		u_prev[i] = 0
		v_prev[i] = 0
		dens[i] = 0
		dens_prev[i] = 0
    end

	-- Need to set initial dens_prev, u_prev and v_prev
	-- u_prev and v_prev may be able to remain 0
end

function resetField()
	    for i=0,size-1 do
		u[i] = 0
		v[i] = 0
		u_prev[i] = 0
		v_prev[i] = 0
		dens[i] = 0
		dens_prev[i] = 0
    end
end

function inject_velocity(i,j, vx,vy)
	u[IX(i+1,j+1)] = (u[IX(i+1,j+1)] + vx)/2
	v[IX(i+1,j+1)] = (v[IX(i+1,j+1)] + vy)/2
end

function inject_dens(i,j,ammount)
	dens[IX(i+1,j+1)] = dens[IX(i+1,j+1)] + ammount
end

function remove_dens(i,j)
	dens[IX(i+1,j+1)] = 0
end

function fluidTick(dt)
	maxDens = -math.huge
	minDens = math.huge

	get_from_game()
	vel_step(u, v, u_prev, v_prev, visc, dt)
	dens_step( dens, dens_prev, u, v, diff, dt)
end

function draw_dens()
	for i=1,fieldWidth do
		for j=1,fieldHeight do
			local colourIndex = math.min(math.max(math.ceil(2.0*dens[IX(i,j)]), 1), COLORS-1);
			--local colourIndex = math.min(math.max(math.ceil(8.0*(dens[IX(i,j)] - minDens) / (maxDens - minDens)), 1), COLORS-1);
			fillRect(colourIndex, 2*(i-1), 2*(j-1), 2, 2)
		end
	end
end

function get_from_game()
    for i=0,size-1 do
	  u_prev[i] = 0
	  v_prev[i] = 0
	  dens_prev[i] = 0
    end
end

-- Do one step in the density solver
function dens_step(x, x0, u, v, diff, dt)
	add_source(x, x0, dt)
	x0, x = x, x0
	diffuse(0, x, x0, diff, dt)
	x0, x = x, x0
	advect(0, x, x0, u, v, dt)	
end

-- Do a velocity step
function vel_step(u, v, u0, v0, visc, dt)
	add_source(u, u0, dt)
	add_source(v, v0, dt)
	u0, u = u, u0
	diffuse(1, u, u0, visc, dt)
	v0, v = v, v0
	diffuse(2, v, v0, visc, dt)
	
	project(u, v, u0, v0)
	u0, u = u, u0
	v0, v = v, v0
	advect(1, u, u0, u0, v0, dt)
	advect(2, v, v0, u0, v0, dt)
	project(u, v, u0, v0)
end

-- Does the added density
function add_source(dens, s, dt)
	for i=0,size-1 do
		dens[i] = dens[i] + dt*s[i]
	end
end

-- Does the density diffusion
function diffuse(b, x, x0, diff, dt)
	a = dt * diff * fieldWidth * fieldHeight
	for k=0,19 do
		for i=1,fieldWidth do
			for j=1,fieldHeight do
				x[IX(i,j)] = (x0[IX(i,j)] + a*(x[IX(i-1,j)] + x[IX(i+1,j)] + x[IX(i,j-1)] + x[IX(i,j+1)])) / (1+4*a)
			end
		end
		set_bnd(b, x)
	end
end

-- Does the vector density stuff
function advect(b, d, d0, u, v, dt)
	
	local dtx = dt*fieldWidth
	local dty = dt*fieldHeight
	local x, y, i0, i1, j0, j1, s0, s1, t0, t1
	for i=1,fieldWidth do
		for j=1,fieldHeight do
			x = i-dtx * u[IX(i,j)]
			y = j-dty * v[IX(i,j)]
			if(x < 0.5) then x = 0.5 end
			if(x > fieldWidth + 0.5) then x = fieldWidth + 0.5 end
			i0 = math.floor(x)
			i1 = i0 + 1
			if(y < 0.5) then y = 0.5 end
			if(y > fieldHeight + 0.5) then y = fieldHeight + 0.5 end
			j0 = math.floor(y)
			j1 = j0 + 1
			
			s1 = x-i0
			s0 = 1-s1
			t1 = y-j0
			t0 = 1-t1
			
			d[IX(i,j)] = s0*(t0*d0[IX(i0,j0)] + t1*d0[IX(i0,j1)]) + s1*(t0*d0[IX(i1,j0)] + t1*d0[IX(i1,j1)])
			
			if d[IX(i,j)] > maxDens then maxDens = d[IX(i,j)] end
			if d[IX(i,j)] < minDens then minDens = d[IX(i,j)] end
			
		end
	end
	set_bnd(b, d)
end

-- Deal with the boundry conditions
function set_bnd(b, d)
	--Do something?
end

-- Projection step
function project(u, v, p, div)
	local hx = 1.0/fieldWidth
	local hy = 1.0/fieldHeight
	for i=1,fieldWidth do
		for j=1,fieldHeight do
			div[IX(i,j)] = -0.5*hx*(u[IX(i+1,j)]-u[IX(i-1,j)]) + -0.5*hy*(v[IX(i,j+1)]-v[IX(i,j-1)])
			p[IX(i,j)] = 0
		end
	end
	set_bnd(0, div)
	set_bnd(0, p)
	
	for k=0,19 do
		for i=1,fieldWidth do
			for j=1,fieldHeight do
				p[IX(i,j)] = (div[IX(i,j)]+p[IX(i-1,j)]+p[IX(i+1,j)]+p[IX(i,j-1)]+p[IX(i,j+1)])/4
			end
		end
		set_bnd(0, p)
	end
	for i=1,fieldWidth do
		for j=1,fieldHeight do
			u[IX(i,j)] = u[IX(i,j)] - 0.5*(p[IX(i+1,j)]-p[IX(i-1,j)])/hx
			v[IX(i,j)] = v[IX(i,j)] - 0.5*(p[IX(i,j+1)]-p[IX(i,j-1)])/hy
		end
	end
	set_bnd(1,u)
	set_bnd(2,v)
end

-- Set the boundry conditions
function set_bnd(b, x)
	
	for i=1,fieldWidth do
		if b == 2  then
			x[IX(i, 0)] = -x[IX(i,1)]
			x[IX(i,fieldHeight+1)] = -x[IX(i,fieldHeight)]
		else
			x[IX(i, 0)] = x[IX(i,1)]
			x[IX(i,fieldHeight+1)] = x[IX(i,fieldHeight)]
		end
	end
	for i=1,fieldHeight do
		if b == 1 then
			x[IX(0, i)] = -x[IX(1,i)]
			x[IX(fieldWidth+1, i)] = -x[IX(fieldWidth, i)]
		else
			x[IX(0, i)] = x[IX(1,i)]
			x[IX(fieldWidth+1, i)] = x[IX(fieldWidth, i)]
		end
	end
	x[IX(0,0)] = 0.5*(x[IX(1,0)]+x[IX(0,1)])
	x[IX(0,fieldHeight+1)] = 0.5*(x[IX(1,fieldHeight+1)]+x[IX(0,fieldHeight)])
	x[IX(fieldWidth+1,0)] = 0.5*(x[IX(fieldWidth,0)]+x[IX(fieldWidth+1,1)])
	x[IX(fieldWidth+1,fieldHeight+1)] = 0.5*(x[IX(fieldWidth,fieldHeight+1)]+x[IX(fieldWidth+1,fieldHeight)])
end

-- Simple conversion make a 1D table act like a 2D one
function IX(i, j)
	return (i + (fieldWidth + 2) * j)
end