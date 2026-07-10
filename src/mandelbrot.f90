module mandelbrot
    use iso_fortran_env, only: real32, real64
    use parameters
    implicit none
    private
    public :: mandelbrot_set

contains

    function pix_to_coord(pix, min_coord, max_coord, n_pix, wpp) result(coord)
        integer, intent(in) :: pix
        integer, intent(in) :: wpp
        real(real64), intent(in) :: min_coord, max_coord
        integer, intent(in) :: n_pix
        real(real64) :: coord

        select case (wpp)
        case (real32)
            block
                real(real32) :: min32, max32, coord32
                min32 = real(min_coord, real32)
                max32 = real(max_coord, real32)
                coord32 = min32 + (max32 - min32) * real(pix - 1, real32) / real(n_pix - 1, real32)
                coord = real(coord32, real64)
            end block
        case default
            block
                real(real64) :: min64, max64, coord64
                min64 = real(min_coord, real64)
                max64 = real(max_coord, real64)
                coord64 = min64 + (max64 - min64) * real(pix - 1, real64) / real(n_pix - 1, real64)
                coord = coord64
            end block
        end select
    end function pix_to_coord

    function iter_calc(x_pix, y_pix, wpp) result(iter)
        integer, intent(in) :: x_pix, y_pix
        integer :: iter
        integer, intent(in) :: wpp

        select case (wpp)
        case (real32)
            block
                real(real32) :: x, y
                real(real32) :: zx, zy, zx2, zy2
                x = real(pix_to_coord(x_pix, x_min, x_max, nx, wpp), real32)
                y = real(pix_to_coord(y_pix, y_min, y_max, ny, wpp), real32)

                zx = 0.0_real32
                zy = 0.0_real32
                zx2 = 0.0_real32
                zy2 = 0.0_real32
                iter = 0

                do while (iter < max_iter .and. zx2 + zy2 <= 4.0_real32) !folge divergiert sobald |z|>2
                    zx2 = zx * zx
                    zy2 = zy * zy
                    zy = 2.0_real32 * zx * zy + y
                    zx = zx2 - zy2 + x
                    iter = iter + 1
                end do
            end block
        case default
            block
                real(real64) :: x, y
                real(real64) :: zx, zy, zx2, zy2
                x = real(pix_to_coord(x_pix, x_min, x_max, nx, wpp), real64)
                y = real(pix_to_coord(y_pix, y_min, y_max, ny, wpp), real64)

                zx = 0.0_real64
                zy = 0.0_real64
                zx2 = 0.0_real64
                zy2 = 0.0_real64
                iter = 0

                do while (iter < max_iter .and. zx2 + zy2 <= 4.0_real64) !folge divergiert sobald |z|>2
                    zx2 = zx * zx
                    zy2 = zy * zy
                    zy = 2.0_real64 * zx * zy + y
                    zx = zx2 - zy2 + x
                    iter = iter + 1
                end do
            end block
        end select
    end function iter_calc

    subroutine mandelbrot_set(x_pix_array, y_pix_array, iter_array, local_ny, rank, sizee, wpp) 
        integer, intent(in) :: x_pix_array(:), y_pix_array(:)
        integer, intent(in) :: local_ny, rank, sizee
        integer, intent(in) :: wpp
        integer, intent(out) :: iter_array(nx, local_ny)

        integer :: i, j
        integer :: progress
        integer :: next_print = 10
        integer :: time(8)

        integer ::middle 
        middle = int(sizee/2)


        do i = 1, size(y_pix_array)

            do j = 1, size(x_pix_array)
                iter_array(j,i) = iter_calc(x_pix_array(j), y_pix_array(i), wpp)
            end do

            if (rank == middle) then
                progress = int(100.0 * i / local_ny)
                if (progress >= next_print) then
                    call date_and_time(values=time)
                    write(*,'("[",I1.1,"](",I2.2,":",I2.2,":",I2.2,") Progress: ",I0,"%")') &
                        rank, time(5), time(6), time(7), progress

                    next_print = next_print + 10
                end if
            end if

        end do

    end subroutine mandelbrot_set

end module mandelbrot