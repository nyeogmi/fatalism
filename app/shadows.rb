# ported from: https://www.albertford.com/shadowcasting/
def compute_fov(
  origin, 
  max_dist,
  &get_z
)
  ox, oy, oz = origin
  sq_max_dist = max_dist * max_dist

  visible = {}
  visible[[ox, oy]] = true

  quadrant = lambda do |dx_tx, dx_ty, dy_tx, dy_ty|
    scan = lambda do |tx, start_slope, end_slope|
      while true 
        was_wall, was_floor = false, false

        min_ty = (tx * start_slope + 0.5).floor()
        max_ty = (tx * end_slope - 0.5).ceil()

        ty = min_ty
        while ty <= max_ty do
          dx, dy = dx_tx * tx + dx_ty * ty, dy_tx * tx + dy_ty * ty
          pdx, pdy = dx_tx * (tx - 1) + dx_ty * ty, dy_tx * (tx - 1) + dy_ty * ty
          
          z = get_z.call(ox + dx, oy + dy)
          zslope = z.nil? ? nil : (z - oz) / tx

          # TODO: 
          is_wall = (
            dx * dx + dy * dy >= sq_max_dist || 
            z == nil || 
            zslope > 0.1 # ||
          )
          is_floor = !is_wall

          if is_wall || ty >= tx * start_slope && ty <= tx * end_slope then
            visible[[ox + dx, oy + dy]] = true 
          end

          start_slope = (2 * ty - 1) / (2 * tx) if was_wall && is_floor
          scan.call(tx + 1, start_slope, (2 * ty - 1) / (2 * tx)) if was_floor && is_wall

          was_wall, was_floor=is_wall, is_floor
          ty += 1
        end

        return unless was_floor
        tx += 1
      end
    end

    scan.call(1, -1, 1)
  end

  quadrant.call(0, 1, -1, 0)
  quadrant.call(0, 1, 1, 0)
  quadrant.call(1, 0, 0, 1)
  quadrant.call(-1, 0, 0, 1)

  return visible.keys
end