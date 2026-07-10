module parameters
    use iso_fortran_env, only: int32, real64, real32
    use json_module
    implicit none
    public :: wp
    public :: nx, ny

    integer :: wp = real64

    integer :: ratio_x, ratio_y 
    integer :: base_size 
    
    integer :: nx, ny

contains
    subroutine load_parameters(file)
        use iso_fortran_env, only: int32, real64, real32
        use json_module
        character(len=*), intent(in) :: file
        logical :: is_found
        integer :: time(8)
        type(json_file) :: json
        character(len=:), allocatable :: wp_string

        call json%initialize()

        call json%load_file(file); if (json%failed()) stop 'Failed to load JSON file'

        json_block: block
            call json%get('wp', wp_string, is_found); if (.not. is_found) exit json_block
            call json%get('ratio_x', ratio_x, is_found); if (.not. is_found) exit json_block
            call json%get('ratio_y', ratio_y, is_found); if (.not. is_found) exit json_block
            call json%get('base_size', base_size, is_found); if (.not. is_found) exit json_block
        end block json_block


        if (.not. is_found) then
            print *, 'Failed to load required keys from JSON file.'
            call json%destroy()
            return
        end if

        select case (trim(adjustl(wp_string)))
            case ('real64')
                wp = real64
            case ('real32')
                wp = real32
            case default
                is_found = .false.
                print *, 'Invalid wp in JSON. Expected real64 or real32.'
        end select

        if(is_found) then
            nx = ratio_x * base_size
            ny = ratio_y * base_size

            call date_and_time(values=time)
            write(*,'("(",I2.2,":",I2.2,":",I2.2,") Found Json File and loaded all Parameters")') &
                time(5), time(6), time(7)
        else
            print *, 'Failed to find x or y in JSON file'
        end if

        call json%destroy()
    end subroutine load_parameters
end module parameters
