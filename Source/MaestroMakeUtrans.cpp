
#include <Maestro.H>
#include <Maestro_F.H>

using namespace amrex;

void
Maestro::MakeUtrans (const Vector<MultiFab>& utilde,
                     const Vector<MultiFab>& ufull,
                     Vector<std::array< MultiFab, AMREX_SPACEDIM > >& utrans,
                     const Vector<std::array< MultiFab, AMREX_SPACEDIM > >& w0mac)
{
    // timer for profiling
    BL_PROFILE_VAR("Maestro::MakeUtrans()",MakeUtrans);

    for (int lev=0; lev<=finest_level; ++lev) {

        // Get the index space and grid spacing of the domain
        const Box& domainBox = geom[lev].Domain();
        const Real* dx = geom[lev].CellSize();

        Real rel_eps = 0.0;
        get_rel_eps(&rel_eps);

        const Real dt2 = 0.5 * dt;

        const Real hx = dx[0];
        const Real hy = dx[1];
#if (AMREX_SPACEDIM == 3)
        const Real hz = dx[2];
#endif
        const int ilo = domainBox.loVect()[0];
        const int ihi = domainBox.hiVect()[0];
        const int jlo = domainBox.loVect()[1];
        const int jhi = domainBox.hiVect()[1];
#if (AMREX_SPACEDIM == 3)
        const int klo = domainBox.loVect()[2];
        const int khi = domainBox.hiVect()[2];
#endif

        const int ppm_type_local = ppm_type;
        const int spherical_local = spherical;

        // get references to the MultiFabs at level lev
        const MultiFab& utilde_mf  = utilde[lev];
        MultiFab Ip, Im;
        Ip.define(grids[lev],dmap[lev],AMREX_SPACEDIM,2);
        Im.define(grids[lev],dmap[lev],AMREX_SPACEDIM,2);

        MultiFab u_mf, v_mf, w_mf;

        if (ppm_type == 0) {
            u_mf.define(grids[lev],dmap[lev],1,utilde[lev].nGrow());
            v_mf.define(grids[lev],dmap[lev],1,utilde[lev].nGrow());

            MultiFab::Copy(u_mf, utilde[lev], 0, 0, 1, utilde[lev].nGrow());
            MultiFab::Copy(v_mf, utilde[lev], 1, 0, 1, utilde[lev].nGrow());

#if (AMREX_SPACEDIM == 3)
            w_mf.define(grids[lev],dmap[lev],1,utilde[lev].nGrow());
            MultiFab::Copy(w_mf, utilde[lev], 2, 0, 1, utilde[lev].nGrow());
#endif

        } else if (ppm_type == 1 || ppm_type == 2) {

            u_mf.define(grids[lev],dmap[lev],1,ufull[lev].nGrow());
            v_mf.define(grids[lev],dmap[lev],1,ufull[lev].nGrow());

            MultiFab::Copy(u_mf, ufull[lev], 0, 0, 1, ufull[lev].nGrow());
            MultiFab::Copy(v_mf, ufull[lev], 1, 0, 1, ufull[lev].nGrow());

#if (AMREX_SPACEDIM == 3)
            w_mf.define(grids[lev],dmap[lev],1,ufull[lev].nGrow());
            MultiFab::Copy(w_mf, ufull[lev], 2, 0, 1, ufull[lev].nGrow());
#endif
        }

#ifdef _OPENMP
#pragma omp parallel
#endif
        for ( MFIter mfi(utilde_mf, TilingIfNotGPU()); mfi.isValid(); ++mfi ) {

            // Get the index space of the valid region
            const Box& tileBox = mfi.tilebox();
            const Box& obx = amrex::grow(tileBox, 1);
            const Box& xbx = mfi.nodaltilebox(0);
            const Box& ybx = mfi.nodaltilebox(1);
#if (AMREX_SPACEDIM == 3)
            const Box& zbx = mfi.nodaltilebox(2);
#endif

            Array4<const Real> const utilde_arr = utilde[lev].array(mfi);
            Array4<const Real> const ufull_arr = ufull[lev].array(mfi);
            Array4<Real> const utrans_arr = utrans[lev][0].array(mfi);
            Array4<Real> const vtrans_arr = utrans[lev][1].array(mfi);
#if (AMREX_SPACEDIM == 3)
            Array4<Real> const wtrans_arr = utrans[lev][2].array(mfi);
#endif
            Array4<Real> const Im_arr = Im.array(mfi);
            Array4<Real> const Ip_arr = Ip.array(mfi);
            Array4<const Real> const w0_arr = w0_cart[lev].array(mfi);
#if (AMREX_SPACEDIM == 3)
            Array4<const Real> const w0macx = w0mac[lev][0].array(mfi);
            Array4<const Real> const w0macy = w0mac[lev][1].array(mfi);
            Array4<const Real> const w0macz = w0mac[lev][2].array(mfi);
#endif

#if (AMREX_SPACEDIM == 2)

            if (ppm_type == 0) {
                // we're going to reuse Ip here as slopex as it has the
                // correct number of ghost zones
                // x-direction
                Slopex(obx, u_mf.array(mfi), 
                       Ip.array(mfi), 
                       domainBox, bcs_u, 
                       1,0);
            } else {

                PPM(obx, utilde_arr, 
                    u_mf.array(mfi), v_mf.array(mfi), 
                    Ip_arr, Im_arr, 
                    domainBox, bcs_u, dx, 
                    false, 0, 0);
           }

            // create utrans
            int bclo = phys_bc[0];
            int bchi = phys_bc[AMREX_SPACEDIM];

            AMREX_PARALLEL_FOR_3D(xbx, i, j, k, 
            {
                Real ulx = 0.0;
                Real urx = 0.0;

                if (ppm_type_local == 0) {

                    ulx = utilde_arr(i-1,j,k,0) 
                        + (0.5-(dt2/hx)*max(0.0,ufull_arr(i-1,j,k,0)))*Ip_arr(i-1,j,k,0);
                    urx = utilde_arr(i  ,j,k,0) 
                        - (0.5+(dt2/hx)*min(0.0,ufull_arr(i  ,j,k,0)))*Ip_arr(i  ,j,k,0);

                } else if (ppm_type_local == 1 || ppm_type_local == 2) {
                    // extrapolate to edges
                    ulx = Ip_arr(i-1,j,k,0);
                    urx = Im_arr(i  ,j,k,0);
                }

                // impose lo i side bc's
                if (i == ilo) {
                    switch (bclo) {
                        case Inflow:
                            ulx = utilde_arr(i-1,j,k,0);
                            urx = utilde_arr(i-1,j,k,0);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            ulx = 0.0;
                            urx = 0.0;
                            break;
                        case Outflow:
                            ulx = min(urx,0.0);
                            urx = ulx;
                            break;
                        case Interior:
                            break;
                    }

                // impose hi i side bc's
                } else if (i == ihi+1) {
                    switch (bchi) {
                        case Inflow:
                            ulx = utilde_arr(i,j,k,0);
                            urx = utilde_arr(i,j,k,0);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            ulx = 0.0;
                            urx = 0.0;
                            break;
                        case Outflow:
                            ulx = max(ulx,0.0);
                            urx = ulx;
                            break;
                        case Interior:
                            break;
                    }
                }

                // solve Riemann problem using full velocity
                bool test = (ulx <= 0.0 && urx >= 0.0) || 
                            (fabs(ulx+urx) < rel_eps);
                utrans_arr(i,j,k) = 0.5*(ulx+urx) > 0.0 ? ulx : urx;
                utrans_arr(i,j,k) = test ? 0.0 : utrans_arr(i,j,k);
            });

            if (ppm_type == 0) {
                // we're going to reuse Im here as slopey as it has the
                // correct number of ghost zones
                Slopey(obx, v_mf.array(mfi), 
                       Im_arr, 
                       domainBox, bcs_u, 
                       1,1);
            } else {
                PPM(obx, utilde_arr, 
                    u_mf.array(mfi), v_mf.array(mfi), 
                    Ip_arr, Im_arr, 
                    domainBox, bcs_u, dx, 
                    false, 1, 1);
           }

           // create vtrans
            bclo = phys_bc[1];
            bchi = phys_bc[AMREX_SPACEDIM+1];

            AMREX_PARALLEL_FOR_3D(ybx, i, j, k, 
            {
                Real vly = 0.0;
                Real vry = 0.0;

                if (ppm_type_local == 0) {
                    // // extrapolate to edges
                    vly = utilde_arr(i,j-1,k,1) 
                        + (0.5-(dt2/hy)*max(0.0,ufull_arr(i,j-1,k,1)))*Im_arr(i,j-1,k,0);
                    vry = utilde_arr(i,j  ,k,1) 
                        - (0.5+(dt2/hy)*min(0.0,ufull_arr(i,j  ,k,1)))*Im_arr(i,j  ,k,0);

                } else if (ppm_type_local == 1 || ppm_type_local == 2) {
                    // extrapolate to edges
                    vly = Ip_arr(i,j-1,k,1);
                    vry = Im_arr(i,j  ,k,1);
                }

                // impose lo side bc's
                if (j == jlo) {
                    switch (bclo) {
                        case Inflow:
                            vly = utilde_arr(i,j-1,k,1);
                            vry = utilde_arr(i,j-1,k,1);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            vry = 0.0;
                            vry = 0.0;
                            break;
                        case Outflow:
                            vly = min(vry,0.0);
                            vry = vly;
                            break;
                        case Interior:
                            break;
                    }

                // impose hi side bc's
                } else if (j == jhi+1) {
                    switch (bchi) {
                        case Inflow:
                            vly = utilde_arr(i,j,k,1);
                            vry = utilde_arr(i,j,k,1);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            vly = 0.0;
                            vry = 0.0;
                            break;
                        case Outflow:
                            vly = max(vly,0.0);
                            vry = vly;
                            break;
                        case Interior:
                            break;
                    }
                }

                // solve Riemann problem using full velocity
                bool test = (vly+w0_arr(i,j,k,AMREX_SPACEDIM-1) <= 0.0 && 
                            vry+w0_arr(i,j,k,AMREX_SPACEDIM-1) >= 0.0) || 
                            (fabs(vly+vry+2.0*w0_arr(i,j,k,AMREX_SPACEDIM-1)) < rel_eps);
                vtrans_arr(i,j,k) = 0.5*(vly+vry)+w0_arr(i,j,k,AMREX_SPACEDIM-1) > 0.0 ? 
                    vly : vry;
                vtrans_arr(i,j,k) = test ? 0.0 : vtrans_arr(i,j,k);
            });

#elif (AMREX_SPACEDIM == 3)

            // x-direction
            if (ppm_type == 0) {
                // we're going to reuse Ip here as slopex as it has the
                // correct number of ghost zones
                Slopex(obx, u_mf.array(mfi), 
                       Ip_arr, 
                       domainBox, bcs_u, 
                       1,0);
            } else {
                PPM(obx, utilde_arr, 
                    u_mf.array(mfi), v_mf.array(mfi), w_mf.array(mfi),
                    Ip_arr, Im_arr, 
                    domainBox, bcs_u, dx, 
                    false, 0, 0);
            }

            // create utrans
            int bclo = phys_bc[0];
            int bchi = phys_bc[AMREX_SPACEDIM];

            AMREX_PARALLEL_FOR_3D(xbx, i, j, k, 
            {
                Real ulx = 0.0;
                Real urx = 0.0;

                if (ppm_type_local == 0) {
                    // extrapolate to edges
                    ulx = utilde_arr(i-1,j,k,0) 
                        + (0.5-(dt2/hx)*max(0.0,ufull_arr(i-1,j,k,0)))*Ip_arr(i-1,j,k,0);
                    urx = utilde_arr(i  ,j,k,0) 
                        - (0.5+(dt2/hx)*min(0.0,ufull_arr(i  ,j,k,0)))*Ip_arr(i  ,j,k,0);
                } else if (ppm_type_local == 1 || ppm_type_local == 2) {
                    // extrapolate to edges
                    ulx = Ip_arr(i-1,j,k,0);
                    urx = Im_arr(i  ,j,k,0);
                }

                // impose lo side bc's
                if (i == ilo) {
                    switch (bclo) {
                        case Inflow:
                            ulx = utilde_arr(i-1,j,k,0);
                            urx = utilde_arr(i-1,j,k,0);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            ulx = 0.0;
                            urx = 0.0;
                            break;
                        case Outflow:
                            ulx = min(urx,0.0);
                            urx = ulx;
                            break;
                        case Interior:
                            break;
                    }

                // impose hi side bc's
                } else if (i == ihi+1) {
                    switch (bchi) {
                        case Inflow:
                            ulx = utilde_arr(i+1,j,k,0);
                            urx = utilde_arr(i+1,j,k,0);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            ulx = 0.0;
                            urx = 0.0;
                            break;
                        case Outflow:
                            ulx = max(ulx,0.0);
                            urx = ulx;
                            break;
                        case Interior:
                            break;
                    }
                }

                if (spherical_local == 1) {
                    // solve Riemann problem using full velocity
                    bool test = (ulx+w0macx(i,j,k) <= 0.0 && 
                                urx+w0macx(i,j,k) >= 0.0) || 
                                (fabs(ulx+urx+2.0*w0macx(i,j,k)) < rel_eps);
                    utrans_arr(i,j,k) = 0.5*(ulx+urx)+w0macx(i,j,k) > 0.0 ? ulx : urx;
                    utrans_arr(i,j,k) = test ? 0.0 : utrans_arr(i,j,k);

                } else {
                    // solve Riemann problem using full velocity
                    bool test = (ulx <= 0.0 && urx >= 0.0) || 
                                (fabs(ulx+urx) < rel_eps);
                    utrans_arr(i,j,k) = 0.5*(ulx+urx) > 0.0 ? ulx : urx;
                    utrans_arr(i,j,k) = test ? 0.0 : utrans_arr(i,j,k);
                }
            });

            // y-direction
            if (ppm_type == 0) {
                // we're going to reuse Im here as slopey as it has the
                // correct number of ghost zones
                Slopey(obx, v_mf.array(mfi), 
                       Im_arr, 
                       domainBox, bcs_u, 
                       1,1);
            } else {
                PPM(obx, utilde_arr, 
                    u_mf.array(mfi), v_mf.array(mfi), w_mf.array(mfi),
                    Ip_arr, Im_arr, 
                    domainBox, bcs_u, dx, 
                    false, 1, 1);
            }

            // create vtrans
            bclo = phys_bc[1];
            bchi = phys_bc[AMREX_SPACEDIM+1];

            AMREX_PARALLEL_FOR_3D(ybx, i, j, k, 
            {
                Real vly = 0.0;
                Real vry = 0.0;

                if (ppm_type_local == 0) {
                    // extrapolate to edges
                    vly = utilde_arr(i,j-1,k,1) 
                        + (0.5-(dt2/hy)*max(0.0,ufull_arr(i,j-1,k,1)))*Im_arr(i,j-1,k,0);
                    vry = utilde_arr(i,j  ,k,1) 
                        - (0.5+(dt2/hy)*min(0.0,ufull_arr(i,j  ,k,1)))*Im_arr(i,j  ,k,0);

                } else if (ppm_type_local == 1 || ppm_type_local == 2) {
                    // extrapolate to edges
                    vly = Ip_arr(i,j-1,k,1);
                    vry = Im_arr(i,j  ,k,1);
                }

                // impose lo side bc's
                if (j == jlo) {
                    switch (bclo) {
                        case Inflow:
                            vly = utilde_arr(i,j-1,k,1);
                            vry = utilde_arr(i,j-1,k,1);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            vly = 0.0;
                            vry = 0.0;
                            break;
                        case Outflow:
                            vly = min(vry,0.0);
                            vry = vly;
                            break;
                        case Interior:
                            break;
                    }

                // impose hi side bc's
                } else if (j == jhi+1) {
                    switch (bchi) {
                        case Inflow:
                            vly = utilde_arr(i,j+1,k,1);
                            vry = utilde_arr(i,j+1,k,1);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            vly = 0.0;
                            vry = 0.0;
                            break;
                        case Outflow:
                            vly = max(vly,0.0);
                            vry = vly;
                            break;
                        case Interior:
                            break;
                    }
                }

                if (spherical_local == 1) {
                    // solve Riemann problem using full velocity
                    bool test = (vly+w0macy(i,j,k) <= 0.0 && 
                                vry+w0macy(i,j,k) >= 0.0) || 
                                (fabs(vly+vry+2.0*w0macy(i,j,k)) < rel_eps);
                    vtrans_arr(i,j,k) = 0.5*(vly+vry)+w0macy(i,j,k) > 0.0 ? 
                                    vly : vry;
                    vtrans_arr(i,j,k) = test ? 0.0 : vtrans_arr(i,j,k);
                } else {
                    // solve Riemann problem using full velocity
                    bool test = (vly <= 0.0 && vry >= 0.0) || 
                                (fabs(vly+vry) < rel_eps);
                    vtrans_arr(i,j,k) = 0.5*(vly+vry) > 0.0 ? vly : vry;
                    vtrans_arr(i,j,k) = test ? 0.0 : vtrans_arr(i,j,k);
                }
            });

            // z-direction
            if (ppm_type == 0) {
                // we're going to reuse Im here as slopez as it has the
                // correct number of ghost zones
                Slopez(obx, w_mf.array(mfi), 
                       Im_arr, 
                       domainBox, bcs_u,  
                       1,2);
            } else {
                PPM(obx, utilde_arr, 
                    u_mf.array(mfi), v_mf.array(mfi), w_mf.array(mfi),
                    Ip_arr, Im_arr, 
                    domainBox, bcs_u, dx, 
                    false, 2, 2);
            }

            // create wtrans
            bclo = phys_bc[2];
            bchi = phys_bc[AMREX_SPACEDIM+2];

            AMREX_PARALLEL_FOR_3D(zbx, i, j, k, 
            {
                Real wlz = 0.0;
                Real wrz = 0.0;

                if (ppm_type_local == 0) {
                    // extrapolate to edges
                    wlz = utilde_arr(i,j,k-1,2) 
                        + (0.5-(dt2/hz)*max(0.0,ufull_arr(i,j,k-1,2)))*Im_arr(i,j,k-1,0);
                    wrz = utilde_arr(i,j,k  ,2) 
                        - (0.5+(dt2/hz)*min(0.0,ufull_arr(i,j,k  ,2)))*Im_arr(i,j,k  ,0);
                } else if (ppm_type_local == 1 || ppm_type_local == 2) {
                    // extrapolate to edges
                    wlz = Ip_arr(i,j,k-1,2);
                    wrz = Im_arr(i,j,k  ,2);
                }

                // impose lo side bc's
                if (k == klo) {
                    switch (bclo) {
                        case Inflow:
                            wlz = utilde_arr(i,j,k-1,2);
                            wrz = utilde_arr(i,j,k-1,2);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            wlz = 0.0;
                            wrz = 0.0;
                            break;
                        case Outflow:
                            wlz = min(wrz,0.0);
                            wrz = wlz;
                            break;
                        case Interior:
                            break;
                    }

                // impose hi side bc's
                } else if (k == khi+1) {
                    switch (bchi) {
                        case Inflow:
                            wlz = utilde_arr(i,j,k+1,2);
                            wrz = utilde_arr(i,j,k+1,2);
                            break;
                        case SlipWall:
                        case NoSlipWall:
                        case Symmetry:
                            wlz = 0.0;
                            wrz = 0.0;
                            break;
                        case Outflow:
                            wlz = max(wlz,0.0);
                            wrz = wlz;
                            break;
                        case Interior:
                            break;
                    }
                }

                if (spherical_local == 1) {
                    // solve Riemann problem using full velocity
                    bool test = (wlz+w0macz(i,j,k) <= 0.0 && 
                                wrz+w0macz(i,j,k) >= 0.0) || 
                                (fabs(wlz+wrz+2.0*w0macz(i,j,k)) < rel_eps);
                    wtrans_arr(i,j,k) = 0.5*(wlz+wrz)+w0macz(i,j,k) > 0.0 ? wlz : wrz;
                    wtrans_arr(i,j,k) = test ? 0.0 : wtrans_arr(i,j,k);
                } else {
                    // solve Riemann problem using full velocity
                    bool test = (wlz+w0_arr(i,j,k,AMREX_SPACEDIM-1)<=0.0 && 
                                wrz+w0_arr(i,j,k,AMREX_SPACEDIM-1)>=0.0) || 
                                (fabs(wlz+wrz+2.0*w0_arr(i,j,k,AMREX_SPACEDIM-1)) < rel_eps);
                    wtrans_arr(i,j,k) = 0.5*(wlz+wrz)+w0_arr(i,j,k,AMREX_SPACEDIM-1) > 0.0 ? wlz : wrz;
                    wtrans_arr(i,j,k) = test ? 0.0 : wtrans_arr(i,j,k);
                }
            });
#endif
        } // end MFIter loop
    } // end loop over levels

    if (finest_level == 0) {
        // fill periodic ghost cells
        for (int lev=0; lev<=finest_level; ++lev) {
            for (int d=0; d<AMREX_SPACEDIM; ++d) {
                utrans[lev][d].FillBoundary(geom[lev].periodicity());
            }
        }

        // fill ghost cells behind physical boundaries
        FillUmacGhost(utrans);
    } else {
        // edge_restriction
        AverageDownFaces(utrans);

        // fill ghost cells for all levels
        FillPatchUedge(utrans);
    }
}